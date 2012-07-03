# -*- encoding: utf-8 -*-

class Location
  include Mongoid::Document
  embedded_in :user
  
  # Fields
  field :zip,      type: String # 邮政编码
  field :address,  type: String # 详细地址
  field :city,     type: String # 所在城市
  field :state,    type: String # 所在省份
  field :country,  type: String # 国家名称
  field :district, type: String # 区/县（只适用于物流API）
  
end