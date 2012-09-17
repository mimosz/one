# -*- encoding: utf-8 -*-

class Rate # 日店铺评价
  include Mongoid::Document

  store_in collection: 'rates'

  belongs_to :user, foreign_key: 'seller_nick'

  # Fields
  
  field :item_rate,    type: Float    # 宝贝与描述相符
  field :item_diff,    type: Float,   default: 0
  field :service_rate, type: Float    # 服务态度
  field :service_diff, type: Float,   default: 0
  field :speed_rate,   type: Float    # 发货速度
  field :speed_diff,   type: Float,   default: 0

  field :avg_refund_days, type: Float    # 平均退款速度
  field :avg_refund_diff, type: Float,   default: 0
  field :refund_rate,     type: Float    # 退款率
  field :refund_diff,     type: Float,   default: 0
  field :complaints_rate, type: Float    # 投诉率
  field :complaints_diff, type: Float,   default: 0
  field :punish_count,    type: Integer  # 处罚数
  field :punish_diff,     type: Float,   default: 0

  field :seller_nick,     type: String
  field :date,            type: Date

  index seller_nick: 1, date: 1
  
  default_scope asc(:date)

  include Sync::Rate
end