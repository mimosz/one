# -*- encoding: utf-8 -*-

class Taobao::Address # 訂單
  include Mongoid::Document
  
  # Embedded
  embedded_in :user
  
  # Fields
  field :contact_id,      type: Integer # 地址库ID
  field :area_id,         type: Integer # 区域ID
  
  field :send_def,        type: Boolean # 是否默认发货地址
  field :get_def,         type: Boolean # 是否默认取货地址
  field :cancel_def,      type: Boolean # 是否默认退货地址
  
  field :contact_name,    type: String # 联系人姓名
  field :province,        type: String # 省
  field :city,            type: String # 市
  field :country,         type: String # 区、县
  field :addr,            type: String # 详细街道地址，不需要重复填写省/市/区
  field :zip_code,        type: String # 地区邮政编码
  field :phone,           type: String # 电话号码,手机与电话必需有一个
  field :mobile_phone,    type: String # 手机号码，手机与电话必需有一个 手机号码不能超过20位
  field :seller_company,  type: String # 公司名称,
  field :memo,            type: String # 备注
  
  field :modify_date,     type: Date # 修改日期时间
  
  field :_id, type: String, default: -> { contact_id }

  def modified_at
    modify_date.strftime("%Y-%m-%d %H:%M:%S")
  end

  include Sync::Address
end