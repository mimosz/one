# -*- encoding: utf-8 -*-

module Sync
  extend ActiveSupport::Concern

  def subusers_sync
    Subuser.sync_create(session, nick)
  end

  def chatpeers_sync(start_at = nil, end_at = Date.yesterday, limit = 1, expire_at = 7.day.ago.to_date)
    if start_at.nil?
      chatpeer = chatpeers.first # 最新记录，日期倒序
      if chatpeer
        start_at = chatpeer.date.to_date.next # 新一天
        start_at = expire_at if expire_at > start_at # 逾期
      else
        start_at = expire_at
      end
    end
    duration = (end_at - start_at).to_i # 时差
    users = subusers.where(status: 1)
    case 
      when duration >= limit # 多日
        range = start_at..end_at # 时间区间
        range.each_slice(limit).each do | day |
          day = day.last
          Chatpeer.sync_create(session, users, day.beginning_of_day, day.end_of_day)
        end
      when duration == 0 # 单日
       Chatpeer.sync_create(session, users, start_at.beginning_of_day, end_at.end_of_day)
      else
         puts "从#{start_at}到#{end_at}。"
    end
  end
  
  def wangwangs_sync(start_at = nil, end_at = Date.yesterday, limit = 1, expire_at = 7.day.ago.to_date)
    if start_at.nil?
      wangwang = wangwangs.first # 最新记录，日期倒序
      if wangwang
        start_at = wangwang.date.to_date.next # 新一天
        start_at = expire_at if expire_at > start_at # 逾期
      else
        start_at = expire_at
      end
    end
    duration = (end_at - start_at).to_i # 时差
    case 
      when duration >= limit # 多日
        range = start_at..end_at # 时间区间
        range.each_slice(limit).each do | day |
          day = day.last
          Wangwang.sync_create(self, day.beginning_of_day, day.end_of_day)
        end
      when duration == 0 # 单日
       Wangwang.sync_create(self, start_at.beginning_of_day, end_at.end_of_day)
     else
       puts "从#{start_at}到#{end_at}。"
    end
  end

  def trades_sync(start_at = nil, end_at = Date.today, limit = 1, expire_at = 90.day.ago.to_date) # 交易
    if start_at.nil?
      trade = trades.recent.limit(1).first # 最新记录，日期倒序
      if trade
        start_at = trade.created.to_date # 新一天
      else
        start_at = expire_at
      end
    end
    start_at = expire_at if expire_at > start_at # 逾期
    duration = (end_at - start_at).to_i # 时差
    case 
      when duration >= limit # 多日
        Trade.sync_create(session, start_at.beginning_of_day, end_at.end_of_day)
      when duration == 0 # 单日
        Trade.sync_update(session, start_at.beginning_of_day, end_at.end_of_day)
      else
       puts "从#{start_at}到#{end_at}。"
    end
  end

  def shippings_sync
    send = trades.where(:consign_time.ne => nil)
    if send.exists?
      start_at = 3.months.ago.beginning_of_day
      sent = send.where(:shipping.ne => nil)
      if sent.exists?
        start_at = sent.last.shipping.modified
      end
      Shipping.sync_create(session, start_at, Time.now)
    end
  end
  
  def orders_sync
    Trade.sync_orders(session, trades.sync_ids)
    Item.sync_update(self)
  end

  def items_sync # 商品
    Item.sync_create(session, :onsale)
    Item.sync_create(session, :inventory)
    Item.sync_items(session, items.sync_ids)
  end
  
  def addresses_sync # 卖家地址
    Address.sync_create(self)
  end

  def members_sync(start_at=nil, end_at=Date.today, grade=nil) # 卖家的会员
    if members.exists?
      start_at = members.recent.limit(1).first.last_trade_time if start_at.nil?
      Member.sync_update(self, start_at.beginning_of_day, end_at.end_of_day, grade)
    else
      Member.sync_create(self)
    end
  end

  def refunds_sync # 退款
    start_at = 3.months.ago.beginning_of_day
     if trades.exists?
      start_at = if refunds.exists?
        refunds.recent.first.modified
      else
        trades.where(:'orders.refund_id' => nil).last.created # 有退款的交易
      end
    end
    Refund.sync_create(session, start_at, Time.now)
  end
  
  def rates_sync # 评价，每日更新
    Rate.sync_create(self)
  end

  private
  
  def get_buyer_ids(session, nicks) # 在售商品
    options = { session: session, method: 'taobao.crm.members.get', page_size: 100, current_page: 1 }
    buyer_ids = []
    buyer_nicks = []
    nicks.each do |nick| # 每40款商品，为一组
      members = Topsdk.get_with(options.merge!(buyer_nick: nick))
      if members.is_a?(Hash) && members.has_key?('members')
        members = members['members']['basic_member']
        members.each do |member|
          buyer_ids << member['buyer_id']
          buyer_nicks << nick
        end
      else
        puts "================================请求"
        puts options
        puts "================================结果"
        puts nick
      end
    end
    if nicks.count != buyer_nicks.count
      puts "User.get_buyer_ids============================错误"
      puts (nicks - buyer_nicks)
    end
    return buyer_ids
  end

end # Sync