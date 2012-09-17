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

  include Sync::SellerCat
end