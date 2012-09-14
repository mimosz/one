# -*- encoding: utf-8 -*-

class Taobao::Shop
  include Mongoid::Document
  
  store_in collection: 'shops'

  # Referenced
  belongs_to :user,     foreign_key: 'nick' # 店长
  belongs_to :shop_cat, foreign_key: 'cid' # 店铺内分类

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

  def store_url
    "http://shop#{sid}.taobao.com"
  end

  def logo_url
    "http://logo.taobao.com/shop-logo#{pic_path}"
  end

  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  include Sync::Shop
end