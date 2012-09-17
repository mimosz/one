# -*- encoding: utf-8 -*-

class Report # 报表
  include Mongoid::Document
  include Redis::Objects

  store_in collection: 'reports'

  # Referenced
  belongs_to :user,  foreign_key: 'seller_nick',  index: true

  # Fields
  field :parent_id,     type: String   # 父
  field :label,         type: String   # 标签
  field :title,         type: String   # 标题

  field :num_iid,       type: Integer  # 商品ID
  field :outer_iid,     type: String   # 商品编码

  field :num,           type: Integer  # 商品数量
  field :refund_num,    type: Integer  # 退货数量
  # 总数
  field :price,         type: Float,  default: 0     
  field :payment,       type: Float,  default: 0
  field :total_fee,     type: Float,  default: 0
  # 最小数
  field :price_min,     type: Float,  default: 0     
  field :payment_min,   type: Float,  default: 0
  field :total_fee_min, type: Float,  default: 0
  # 最大数
  field :price_max,     type: Float,  default: 0     
  field :payment_max,   type: Float,  default: 0
  field :total_fee_max, type: Float,  default: 0

  field :discount_fee,  type: Float,  default: 0
  field :adjust_fee,    type: Float,  default: 0
  field :fixed_price,   type: Float,  default: 0 # 吊牌价 
  field :refund_fee,    type: Float,  default: 0 # 退货金额

  field :date,          type: Date # 时间

  class << self
    def report_to(seller, start_at, end_at)
      range = start_at.beginning_of_day..end_at.end_of_day
      trades = seller.trades.where( pay_time: range )
      item_ids = distinct('orders.num_iid')
      items = seller.items.in(item_ids)
      batch = {}
      trades.each do |trade|
        trade.orders.each do |order|

        end
      end

    end

    def report_by_sales(batch, order)
      report = case
        when order.is_oversold
          batch[:oversold]   = OversoldDaily.new  unless batch.has_key?(:oversold) # 超卖
          batch[:oversold]
        when trade.is_brand_sale
          batch[:brand_sale] = BrandSaleDaily.new unless batch.has_key?(:brand_sale) # 特卖
          batch[:brand_sale]
        else
          batch[:normal]     = Daily.new          unless batch.has_key?(:normal) # 常规
          batch[:normal]
        end
      order_sum(report, order)
    end

    private

    def to_hash(rows, field)
      new_hash = {}
      rows.each do |row|
        key = row.send(field)
        new_hash[key] = row unless new_hash.has_key?( key )
      end
      new_hash
    end

    def order_sum(report, order, fixed_price=0)
      # 订单
      report[:num]          += order[:num]
      report[:price]        += (order[:price] * order[:num]).to_f
      report[:payment]      += order[:payment]
      report[:total_fee]    += order[:total_fee]
      report[:adjust_fee]   += order[:adjust_fee] 
      report[:discount_fee] += order[:discount_fee]
      report[:refund_num]   += order[:refund_num]
      report[:refund_fee]   += order[:refund_fee]
      report[:fixed_price]  += (fixed_price * order[:num]).to_f
      report[:total_fee_max] = order.total_avg   if order.total_avg   > report[:total_fee_max] # 最大应付
      report[:payment_max]   = order.payment_avg if order.payment_avg > report[:payment_max] # 最大实付
      report[:price_max]     = order[:price]       if order[:price]      > report[:price_max]    # 最大售价
      report[:total_fee_min] = order.total_avg   if order.total_avg   < report[:total_fee_min]  # 最小应付
      report[:price_min]     = order[:price]       if order[:price]       < report[:price_min]  # 最小售价
      report[:payment_min]   = order.payment_avg if order.payment_avg < report[:payment_min]   # 最小实付
    end
  end
  
end