# -*- encoding: utf-8 -*-

class Taobao::ItemProp # 商品属性
  include Mongoid::Document

  store_in collection: 'item_props'

  has_many    :items,       foreign_key: 'cid'
  embeds_many :prop_values
  
  # Fields
  field :cid,      type: Integer # 商品所属的叶子类目 id
  field :pid,      type: Integer # 属性ID
  field :name,     type: String  # 属性名

  field :_id, type: String, default: -> { pid }

  include Sync::ItemProp
end