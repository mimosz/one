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
    def sync_create
      options = { method: 'taobao.shopcats.list.get', fields: shop_cat_fields}
      shop_cats = Topsdk.get_with(options)
      if shop_cats.is_a?(Hash) && shop_cats.has_key?('shop_cats')
        shop_cats = shop_cats['shop_cats']['shop_cat']
        ids = shop_cat_ids
        shop_cats.each do |shop_cat|
          if ids.include?(shop_cat['cid'])
            where(cid: shop_cat['cid']).update(shop_cat)
          else
            create(shop_cat)
          end
        end
      else
        logger.error '////-- ShopCat.sync_create --////'
        logger.error '/*'
        logger.error options.to_s
        logger.error '---------------------------------'
        logger.error shop_cats.to_s
        logger.error '*/'
      end
    end

    private

    def shop_cat_ids
      ShopCat.all.distinct('cid')
    end

    def shop_cat_fields
     self.fields.keys.join(',')
    end
  end
end