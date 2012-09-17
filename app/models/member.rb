# -*- encoding: utf-8 -*-

class Member 
  include Mongoid::Document
  include Redis::Objects

  store_in collection: 'members'

  # Referenced
  belongs_to :user, foreign_key: 'seller_nick', index: true  # 店铺
  # Embedded
  embeds_many :receivers

  # Fields
  field :grade,             type: Integer,  default: 0
  field :trade_count,       type: Integer
  field :close_trade_count, type: Integer
  field :item_num,          type: Integer
  field :relation_source,   type: Integer
  
  field :buyer_id,          type: Integer
  field :seller_id,         type: Integer

  field :trade_amount,       type: Float,  default: 0 
  field :close_trade_amount, type: Float,  default: 0 

  field :group_ids,          type: Array,  default: []

  field :biz_order_id,      type: String
  field :buyer_nick,        type: String
  field :seller_nick,       type: String
  field :status,            type: String

  field :last_trade_time,   type: DateTime
  field :synced_at,         type: DateTime

  field :_id, type: String, default: -> { "#{seller_nick}:#{buyer_nick}" }

  index seller_nick: 1, buyer_nick: 1
  index 'receivers.receiver_state' => 1
  index({ 'receivers.receiver_mobile' => 1, 'receivers.receiver_name' => 1, 'receivers.receiver_address' => 1 }, { unique: true })
  index last_trade_time: 1

  after_save :cache_receivers

  def cache_receivers
    if synced_at.nil?
      trade = Trade.where(_id: biz_order_id).last
      if trade
        current_receiver = nil
        self.synced_at = Time.now
        if receivers.exists?
          current_receiver = receivers.where(
            receiver_mobile:  trade.receiver_mobile,
            receiver_name:    trade.receiver_name,
            receiver_address: trade.receiver_address,
          ).last
        end
        # 检测：手机号、姓名、地址，是否存在。
        if current_receiver.nil?
          specs = mobile_specs(trade.receiver_mobile)
          self.receivers << Receiver.new( trade.merge(mobile_carrier: specs[:carrier], mobile_network: specs[:network]) )
        end
        self.save
      end
    end
  end

  def mobile_specs(mobile)
    mobile = mobile.to_s[0..2].to_i # 号段
    china_mobile = { 
      '2G' => [134, 135, 136, 137, 138, 139, 150, 151, 152, 157, 158, 159, 182], 
      '3G' => [187, 188]
    }
    china_unicom = { 
      '2G' => [130, 131, 132, 155, 156], 
      '3G' => [185, 186]
    }
    china_telecom = { 
      '2G' => [133, 153], 
      '3G' => [180, 189]
    }
    case
    when china_mobile['2G'].include?(mobile)
      { carrier: '中国移动', network: '2G' }
    when china_mobile['3G'].include?(mobile)
      { carrier: '中国移动', network: '3G' }
    when china_unicom['2G'].include?(mobile)
      { carrier: '中国联通', network: '2G' }
    when china_unicom['3G'].include?(mobile)
      { carrier: '中国联通', network: '3G' }
    when china_telecom['2G'].include?(mobile)
      { carrier: '中国电信', network: '2G' }
    when china_telecom['3G'].include?(mobile)
      { carrier: '中国电信', network: '3G' }
    else
      { carrier: mobile, network: mobile }
    end
  end

  def trade_pre
    avg = (trade_amount.to_f / trade_count.to_f)
    avg > 0 ? avg.round(2) : nil
  end

  def trades # 交易
    conditions = { seller_nick: seller_nick, buyer_nick: buyer_nick }
    Trade.where( conditions ).desc(:created, :modified)
  end
  
  def chatpeers # 聊天记录
    conditions = { seller_nick: seller_nick, uid: "cntaobao#{buyer_nick}" }
    Chatpeer.where( conditions ).desc(:date)
  end

  def refunds # 退款
    conditions = { seller_nick: seller_nick, buyer_nick: buyer_nick }
    Refund.where( conditions ).desc(:created, :modified)
  end

  def level
    case grade
      when 0
       '无会员等级'
      when 1
       '普通会员'
      when 2
       '高级会员'
      when 3
       'VIP会员'
      when 4
       '至尊VIP会员'
    end
  end

  include Sync::Member
end