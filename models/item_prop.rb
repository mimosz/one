# -*- encoding: utf-8 -*-

class ItemProp # 商品属性
  include Mongoid::Document
  has_many :items, foreign_key: 'cid'
  embeds_many :prop_values, class_name: 'PropValue'
  
  # Fields
  field :cid,      type: Integer # 商品所属的叶子类目 id
  field :pid,      type: Integer # 属性ID
  field :name,     type: String  # 属性名

  field :_id, type: String, default: -> { pid }

  class << self

    def sync_create(session, cid)
      options = { session: session, method: 'taobao.itemprops.get', cid: cid, is_sale_prop: true, fields: prop_fields }
	  item_props = Topsdk.get_with(options)
	  item_props = ['item_props']['item_prop']
	  if item_props.count > 0
	     item_props.each do |item_prop|
		    item_prop['cid'] = cid
		    item_prop['prop_values'] = item_prop['prop_values']['prop_value']
		    ItemProp.create(item_prop)        
	     end
       end
    end

  	private

  	def prop_fields
       'pid,name,prop_values'
     end
  end
end