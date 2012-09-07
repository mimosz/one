# -*- encoding: utf-8 -*-

class SellerCat < ShopCat
  # Fields
  field :sort_order,  type: Integer # 页面上的排序
  field :type,        type: String  # 店铺类目类型
  field :pic_url,     type: String  # 链接图片地址
  field :seller_nick, type: String

  def parse_type
    case type
      when 'manual_type'
       '手动分类'
      when 'new_type'
       '新品上价'
      when 'tree_type'
       '二三级类目树'
      when 'property_type'
       '属性叶子类目树'
      when 'brand_type'
       '品牌推广'
      else
       type
    end
  end

  class << self
    def sync_create(session, seller_nick)
      options = { session: session, method: 'taobao.sellercats.list.get', nick: seller_nick }
      seller_cats = Topsdk.get_with(options)
      if seller_cats.is_a?(Hash) && seller_cats.has_key?('seller_cats')
        seller_cats = seller_cats['seller_cats']['seller_cat']
        ids = seller_cat_ids(seller_nick)
        seller_cats.each do |seller_cat|
          if ids.include?(seller_cat['cid'])
            where(seller_nick: seller_nick, cid: seller_cat['cid']).update(seller_cat)
          else
            seller_cat['seller_nick'] = seller_nick
            create(seller_cat)
          end
        end
      else
        logger.error '////-- SellerCat.sync_create --////'
        logger.error '/*'
        logger.error options.to_s
        logger.error '-----------------------------------'
        logger.error seller_cats.to_s
        logger.error '*/'
      end
    end

    private

    def seller_cat_ids(seller_nick)
      SellerCat.where(seller_nick: seller_nick).distinct('cid')
    end
  end
end