
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
          seller_cats = shop['seller_cats']['seller_cat']
        else
          puts "SellerCat.sync_create============================错误"
          puts "======请======求======"
          puts options
          puts "======结======果======"
          puts seller_cats
        end
      end
    end
  end
end