# -*- encoding: utf-8 -*-

class Shop
  include Mongoid::Document
  belongs_to :shop_cat, foreign_key: 'cid'

  # Fields
  field :sid,       type: Integer   # 店铺编号
  field :cid,       type: Integer   # 店铺，所属的类目
  
  field :nick,      type: String    # 卖家昵称
  field :title,     type: String    # 店铺标题
  field :desc,      type: String    # 店铺描述
  field :bulletin,  type: String    # 店铺公告
  field :pic_path,  type: String    # 店标地址

  field :created,   type: DateTime  # sku创建日期
  field :modified,  type: DateTime  # sku最后修改日期
  
  field :_id, type: String, default: -> { sid }

  index nick: 1

  def shop_url
    "http://shop#{sid}.taobao.com"
  end

  def logo_url
    "http://logo.taobao.com/shop-logo#{pic_path}"/c7/66/T1_zOqXlhBXXb1upjX
  end

  class << self
    def sync_create(session, seller_nick)
      options = { session: session, method: 'taobao.shop.get', nick: seller_nick, fields: shop_fields}
        shop = Topsdk.get_with(options)
        if shop.is_a?(Hash) && shop.has_key?('shop')
          create(shop['shop'])
        else
          puts "Shop.sync_create============================错误"
          puts "======请======求======"
          puts options
          puts "======结======果======"
          puts shop
        end
      end
    end

    private

    def shop_fields
     self.fields.keys.join(',')
    end
  end
end
