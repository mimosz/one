# -*- encoding: utf-8 -*-

class ShopCat
  include Mongoid::Document
  has_many :shops,  foreign_key: 'cid'

  # Fields
  field :cid,        type: Integer # 类目编号
  field :parent_cid, type: Integer # 父类目编号
  field :is_parent,  type: Boolean # 该类目是否为父类目
  field :name,       type: String  # 类目名称

  field :_id, type: String, default: -> { cid }

  class << self
    def sync_create()
      options = { session: session, method: 'taobao.shop.get', fields: shop_cat_fields}
        shop_cats = Topsdk.get_with(options)
        if shop_cats.is_a?(Hash) && shop_cats.has_key?('shop_cats')
          shop_cats = shop_cats['shop_cats']['shop_cat']
        else
          puts "ShopCat.sync_create============================错误"
          puts "======请======求======"
          puts options
          puts "======结======果======"
          puts shop_cats
        end
      end
    end

    private

    def shop_cat_fields
     self.fields.keys.join(',')
    end
  end
end