# -*- encoding: utf-8 -*-

class Taobao::Trade
  include Mongoid::Document
  include Redis::Objects

  store_in collection: 'trades'

  # Referenced
  belongs_to :user, foreign_key: 'seller_nick', index: true
  belongs_to :item, foreign_key: 'num_iid'
  has_one :refund,  foreign_key: 'tid'  # 退款
  # Embedded
  embeds_many :orders   # 订单
  embeds_one  :shipping # 快递
  
  # Fields
  field :num,               type: Integer
  field :num_iid,           type: Integer
  field :alipay_id,         type: Integer
  field :tid,               type: Integer
  field :seller_flag,       type: Integer

  field :has_post_fee,      type: Boolean # 是否包含邮费
  field :buyer_rate,        type: Boolean
  field :is_lgtype,         type: Boolean # 是否需要物流宝发货
  field :is_brand_sale,     type: Boolean # 品牌特卖订单
  field :is_force_wlb,      type: Boolean # 强制使用物流宝发货

  field :price,             type: Float
  field :payment,           type: Float
  field :total_fee,         type: Float
  field :discount_fee,      type: Float
  field :point_fee,         type: Float
  field :post_fee,          type: Float
  field :real_point_fee,    type: Float
  field :cod_fee,           type: Float
  
  field :title,             type: String
  field :pic_path,          type: String
  field :receiver_address,  type: String
  field :receiver_city,     type: String
  field :receiver_district, type: String
  field :receiver_mobile,   type: String
  field :receiver_name,     type: String
  field :receiver_state,    type: String
  field :receiver_zip,      type: String
  field :seller_nick,       type: String
  field :shipping_type,     type: String
  
  field :alipay_no,         type: String
  field :buyer_area,        type: String
  field :buyer_nick,        type: String
  field :cod_status,        type: String
  field :status,            type: String
  field :type,              type: String
  
  field :pay_time,          type: DateTime
  field :end_time,          type: DateTime
  field :consign_time,      type: DateTime
  field :created,           type: DateTime
  field :modified,          type: DateTime
  field :synced_at,         type: DateTime
  
  field :_id, type: String, default: -> { tid }
  
  index({ seller_nick: 1, tid: 1 }, { unique: true })
  index pay_time: 1
  index 'orders.oid' => 1

  scope :recent, desc(:created, :modified)

  def member # 会员
    Taobao::Member.where(seller_nick: seller_nick, buyer_nick: buyer_nick).last 
  end
  
  def wangwang_url # 旺旺
    "http://www.taobao.com/webww/ww.php?ver=3&amp;touid=#{buyer_nick}&amp;siteid=cntaobao&amp;charset=utf-8"
  end

  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def sent_at
    consign_time.in_time_zone unless consign_time.nil?
  end
  
  def paid_at
    pay_time.in_time_zone unless pay_time.nil?
  end

  def parse_status
    case status
      when 'TRADE_NO_CREATE_PAY'
       '没有创建支付宝交易'
      when 'WAIT_BUYER_PAY'
       '待付款'
      when 'WAIT_SELLER_SEND_GOODS'
       '待发货'
      when 'WAIT_BUYER_CONFIRM_GOODS'
       '待收货'
      when 'TRADE_BUYER_SIGNED'
       '已签收'
      when 'TRADE_FINISHED'
       '交易成功'
      when 'TRADE_CLOSED'
       '退款成功'
      when 'TRADE_CLOSED_BY_TAOBAO'
       '交易关闭'
      else
       status
    end
  end
  
  class << self
    
    def sync_update(session, start_at, end_at, page_no=1, page_size=100) # 賣家
        options = { # 基础参数
          session: session, 
          method: 'taobao.trades.sold.increment.get', 
          start_modified: start_at.strftime("%Y-%m-%d %H:%M:%S"), 
          end_modified: end_at.strftime("%Y-%m-%d %H:%M:%S"), 
          fields: trade_heads, 
          page_no: page_no,
          page_size: page_size
        }
        process_sync(options)
    end
    
    def sync_create(session, start_at, end_at, page_no = 1, page_size = 100) # 賣家
        options = { # 基础参数
          session: session, 
          method: 'taobao.trades.sold.get', 
          start_created: start_at.strftime("%Y-%m-%d %H:%M:%S"), 
          end_created: end_at.strftime("%Y-%m-%d %H:%M:%S"),
          fields: trade_heads, 
          page_no: page_no,
          page_size: page_size, 
        }
        process_sync(options)
    end
    
    def sync_orders(session, tids)
      result = []
      options = { # 基础参数
        session: session, 
        method: 'taobao.trade.fullinfo.get', 
        fields: trade_fields,
      }
      puts "Trade.sync_orders============================提示"
      puts "本次同步， #{tids.count} 单"
      tids.each do |trade_id| 
       # 已有交易
       trade = Topsdk.get_with(options.merge!(tid: trade_id))
       if trade.is_a?(Hash) && trade.has_key?('trade')
         trade = trade['trade']
         trade['synced_at'] = Time.now
         trade['orders'] = trade['orders']['order']
         current_trade = where(_id: trade_id.to_s).last
         if current_trade.nil?
            current_trade = create(trade)
            return current_trade if tids.count == 1 # 补漏
         else
           current_trade.update_attributes(trade)
         end
         result << trade_id
       else
         puts "Trade.sync_orders============================错误"
         puts "======请======求======"
         puts options
         puts "======结======果======"
         puts trade
       end
      end
      if tids.count != result.count
        puts "Trade.sync_orders============================错误"
        puts (tids - result)
      end
    end

    private
  
    def process_sync(options, total_page = 0)
      created   = [] # 新增
      updated   = [] # 更新
      unchanged = [] # 无变化
      page_no = options[:page_no].to_i # 页数
      # 获取交易数据
      trades = Topsdk.get_with(options)
      # 判断结果
      if trades.is_a?(Hash) && trades.has_key?('total_results')
        # 分页参数
        total_results = trades['total_results'].to_i # 总数     
        # 判断记录数
        if total_results > 0
           if total_page == 0 # 总页数
              page_size = options[:page_size].to_i    # 每页数
             total_page = (total_results / page_size)
             total_page += 1 if (total_results % page_size) > 0
           end
           
           trades = trades['trades']['trade'] # 交易
           
           if trades.count > 0
             trades.each do |trade| # 循环交易
               # 已有交易
               current_trade = where(_id: trade['tid'].to_s).last
               case
               when current_trade.nil?
                  created << trade['tid'] # 新增
                  create(trade)        
               when trade['modified'] > current_trade.modified_at
                  updated << trade['tid'] # 更新
                  # 未付款，不更新订单
                  trade['synced_at'] = nil unless trade['pay_time'].nil?
                  current_trade.update_attributes(trade)
               else
                  unchanged << trade['tid'] # 无变化
               end
             end
           end
           puts "Trade.process_sync==============（#{page_no}/#{total_page}页）==============提示"
           puts "本次同步，共获取 #{trades.count} 单，其中 新增 #{created.count}，更新 #{updated.count}，无变化 #{unchanged.count} 单"
           # 循环
           process_sync(options.merge!(page_no: (page_no + 1)), total_page) if total_page > page_no
        else
          if total_page > 0
             puts "Trade.process_sync============================重试"
             process_sync(options, total_page)
           else
             puts "Trade.process_sync============================错误"
             puts "======请======求======"
             puts options
             puts "======结======果======"
             puts trades
           end
        end
      else
        if total_page > 0
           puts "Trade.process_sync============================重试"
           process_sync(options, total_page)
         else
           puts "Trade.process_sync============================错误"
           puts "======请======求======"
           puts options
           puts "======结======果======"
           puts trades
         end
      end
    end
    
    def trade_heads
     'tid, num_iid, seller_nick, buyer_nick, pay_time, created, modified, status'
    end
    
    def trade_fields
     (['orders'] + self.fields.keys).join(',')
    end
  end
end