# -*- encoding: utf-8 -*-

class Refund
  include Mongoid::Document

  store_in collection: 'refunds'

  # Referenced
  belongs_to :trade,  foreign_key: 'tid', index: true # 交易
  belongs_to :user,   foreign_key: 'seller_nick', index: true # 店铺
  
  field :refund_id,       type: Integer
  field :num,             type: Integer

  field :has_good_return, type: Boolean
  
  field :total_fee,       type: Float
  field :refund_fee,      type: Float
  field :payment,         type: Float

  field :tid,             type: String # 交易
  field :oid,             type: String
  field :num_iid,         type: String # 货品
  
  field :buyer_nick,      type: String
  field :seller_nick,     type: String # 店铺
  field :order_status,    type: String
  field :status,          type: String
  field :good_status,     type: String
  field :reason,          type: String
  field :desc,            type: String
  field :title,           type: String
  field :company_name,    type: String
  field :sid,             type: String
  field :address,         type: String
  
  field :created,         type: DateTime
  field :modified,        type: DateTime
  
  field :_id, type: String, default: -> { refund_id }

  after_save :order_update

  def parse_status
    case status
      when /WAIT_SELLER_AGREE/
        '待确认'
      when /WAIT_BUYER_RETURN_GOODS/
        '待退货'
      when /WAIT_SELLER_CONFIRM_GOODS/
        '待收货'
      when /SELLER_REFUSE_BUYER/
        '拒绝'
      when /CLOSED/
        '关闭'
      when /SUCCESS/
        '完结'
    end
  end

  def member # 会员
    Member.where(seller_nick: seller_nick, buyer_nick: buyer_nick).last 
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def order_update
      if trade
        order = if tid == oid
          trade.orders.last
        else
          trade.orders.where(_id: oid).last
        end
        unless order.nil?
          order.update_attributes(
            refund_id: refund_id,
            refund_num: num,
            refund_fee: refund_fee,
            refund_status: status,
          )
        else
          puts "警告：无 #{oid} 订单"
        end
      end
  end
  
  include Sync::Refund
end