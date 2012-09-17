# -*- encoding: utf-8 -*-

class ShopCat
  include Mongoid::Document

  store_in collection: 'shop_cats'

  has_many :shops,  foreign_key: 'cid'

  # Fields
  field :cid,        type: Integer # 类目编号
  field :parent_cid, type: Integer # 父类目编号
  field :is_parent,  type: Boolean # 该类目是否为父类目
  field :name,       type: String  # 类目名称

  field :_id, type: String, default: -> { cid }

  include Sync::ShopCat
end