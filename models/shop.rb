# -*- encoding: utf-8 -*-

class Shop
  include Mongoid::Document
  # Referenced
  belongs_to :user,     foreign_key: 'nick' # 店长
  belongs_to :shop_cat, foreign_key: 'cid' # 店铺内分类

  has_many :trades,       foreign_key: 'seller_nick' # 交易
  has_many :refunds,      foreign_key: 'seller_nick' # 退款
  has_many :items,        foreign_key: 'nick'        # 商品
  has_many :subusers,     foreign_key: 'seller_nick' # 子账号
  has_many :chatpeers,    foreign_key: 'seller_nick' # 聊天记录
  has_many :wangwangs,    foreign_key: 'seller_nick' # 旺旺绩效
  has_many :members,      foreign_key: 'seller_nick' # 会员
  has_many :rates,        foreign_key: 'seller_nick' # 店铺评分
  has_many :filter_lists, foreign_key: 'seller_nick' # 统计过滤表

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
  
  field :_id, type: String, default: -> { nick }

  index nick: 1

  def shop_url
    "http://shop#{sid}.taobao.com"
  end

  def logo_url
    "http://logo.taobao.com/shop-logo#{pic_path}"
  end

  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  class << self
    def sync_create(session, seller_nick)
      options = { session: session, method: 'taobao.shop.get', nick: seller_nick, fields: shop_fields}
      shop = Topsdk.get_with(options)
      if shop.is_a?(Hash) && shop.has_key?('shop')
        shop = shop['shop']
        current_shop = Shop.where(_id: shop['sid'].to_s ).last
        if current_shop.nil?
          create(shop)
        elsif shop.has_key?('modified') && (shop['modified'] > current_shop.modified_at)
          current_shop.update_attributes!(shop)
        end
      else
        logger.error '////-- Shop.sync_create --////'
        logger.error '/*'
        logger.error options.to_s
        logger.error '------------------------------'
        logger.error shop.to_s
        logger.error '*/'
      end
    end

    private

    def shop_fields
     self.fields.keys.join(',')
    end
  end
end