# -*- encoding: utf-8 -*-

class ItemProp # 商品属性
  include Mongoid::Document

  store_in collection: 'item_props'

  embeds_many :prop_values
  
  # Fields
  field :cid,      type: Integer # 商品所属的叶子类目 id
  field :pid,      type: Array # 属性ID
  field :name,     type: Array  # 属性名

  field :_id, type: String, default: -> { cid }

  include Sync::ItemProp
end