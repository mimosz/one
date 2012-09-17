# -*- encoding: utf-8 -*-

class Item # 商品
  include Mongoid::Document
  include Redis::Objects

  store_in collection: 'items'

  # Referenced
  belongs_to :user,     foreign_key: 'nick',  index: true
  has_many :item_props, foreign_key: 'cid'     # 商品属性
  has_many :trades,     foreign_key: 'num_iid' # 订单
  # Embedded
  embeds_many :skus

  # Fields
  field :num_iid,         type: Integer  # 商品数字id
  field :cid,             type: Integer  # 商品所属的叶子类目 id
  field :num,             type: Integer  # 商品数量
  field :sub_stock,       type: Integer  # 标识商品减库存的方式：1-拍下减库存，2-付款减库存。
  field :volume,          type: Integer  # 对应搜索商品列表页的最近成交量
  field :product_id,      type: Integer  # 宝贝所属产品的id
  # 从上架日期起，近7天的
  field :duration,        type: String,   default: '暂无'  # 周转天数
  field :range_num,       type: Integer,   default: 0  # 周转量
  # 昨日销量
  field :prev_num,        type: Integer,   default: 0  
  # 周转，价格区间
  field :range_max,       type: Float,   default: 0     
  field :range_min,       type: Float,   default: 0
  # 昨日销售，价格区间
  field :prev_max,        type: Float ,  default: 0    
  field :prev_min,        type: Float,   default: 0
  # 吊牌价
  field :fixed_price,     type: Float,   default: 0
  
  field :price,           type: Float    # 商品价格 
  field :post_fee,        type: Float    # 平邮费用
  field :express_fee,     type: Float    # 快递费用
  field :ems_fee,         type: Float    # ems费用
  
  field :pic_url,         type: String   # 商品主图片地址
  field :title,           type: String   # 商品标题
  field :detail_url,      type: String   # 商品url
  field :outer_id,        type: String   # 商家外部编码
  field :nick,            type: String   # 卖家昵称
  field :type,            type: String   # 商品类型
  field :freight_payer,   type: String   # 运费承担方式
  field :approve_status,  type: String   # 商品上传后的状态
  field :seller_cids,     type: Array    # 商所属的店铺内，自定义类目

  field :is_taobao,       type: Boolean  # 是否在淘宝显示
  
  field :list_time,       type: DateTime # 上架时间
  field :delist_time,     type: DateTime # 下架时间
  field :created,         type: DateTime # Item的发布时间
  field :modified,        type: DateTime # 商品修改时间
  field :synced_at,       type: DateTime
  
  field :_id, type: String, default: -> { num_iid }
  index nick: 1, num_iid: 1
  index 'skus.outer_id' => 1
  
  def item_url
    "http://item.taobao.com/item.htm?id=#{num_iid}"
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def range_rate
    (range_num.to_f / duration.to_f).round(1) if range_num > 0
  end
  
  include Sync::Item
  include Kaminari::MongoidExtension::Criteria
  include Kaminari::MongoidExtension::Document
end