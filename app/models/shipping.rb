# -*- encoding: utf-8 -*-

class Shipping # 运單
  include Mongoid::Document

  store_in collection: 'shippings'

  # Embedded
  embedded_in :trade
  
  # Fields
  field :tid,             type: Integer
  
  field :order_code,      type: String
  field :seller_nick,     type: String # 卖家昵称
  field :buyer_nick,      type: String # 买家昵称
  field :out_sid,         type: String # 运单号.具体一个物流公司的运单号码.
  field :item_title,      type: String # 连衣花裙	货物名称
  field :receiver_name,   type: String # 收件人姓名
  field :freight_payer,   type: String # 谁承担运费
  field :seller_confirm,  type: String # 卖家是否确认发货
  field :company_name,    type: String # 物流公司名称
  field :status,          type: String # 物流订单状态
  field :type,            type: String # 物流方式
  
  field :delivery_start,  type: Date # 预约取货开始时间
  field :delivery_end	,   type: Date # 预约取货结束时间
  field :created,         type: Date # 运单创建时间
  field :modified,        type: Date # 运单修改时间

  field :_id,             type: String, default: -> { out_sid }
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def parse_status
    case status
      when 'CREATED'
       '待发货'
      when 'RECREATED'
       '订单重新创建'
      when 'CANCELLED'
       '订单已取消'
      when 'CLOSED'
       '订单关闭'
      when 'SENDING'
       '等候发送给物流公司'
      when 'ACCEPTING'
       '已发送给物流公司,等待接单'
      when 'ACCEPTED'
       '物流公司已接单'
      when 'REJECTED'
       '物流公司不接单'
      when 'PICK_UP'
       '物流公司揽收成功'
      when 'PICK_UP_FAILED'
       '物流公司揽收失败'
      when 'LOST'
       '物流公司丢单'
      when 'REJECTED_BY_RECEIVER'
       '对方拒签'
      when 'ACCEPTED_BY_RECEIVER'
       '对方已签收'
      else
       status
    end
  end
  
  include Sync::Shipping
  
end