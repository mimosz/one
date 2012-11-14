# -*- encoding: utf-8 -*-

class User
  include Mongoid::Document
  include Store

  store_in collection: 'users'

  # Referenced
  belongs_to :ownable,   polymorphic: true, index: true # 店长
  has_many   :shops,     foreign_key: 'nick' # 店铺
  has_many   :employees, foreign_key: 'seller_nick' # 店铺
  # Embedded
  embeds_many :addresses
  embeds_one  :seller_credit, class_name: 'UserCredit' # 卖家信用
  
  # Validations
  validates_presence_of   :session
  validates_uniqueness_of :session
  validates_length_of     :session, minimum: 48, maximum: 64
  # Fields
  field :item_img_num,              type: Integer  # 可上传商品图片数量
  field :item_img_size,             type: Integer  # 单张商品图片最大容量(商品主图大小)
  field :prop_img_num,              type: Integer  # 可上传属性图片数量
  field :prop_img_size,             type: Integer  # 单张销售属性图片最大容量（非主图的商品图片和商品属性图片）
  
  field :has_more_pic,              type: Boolean  # 是否购买多图服务
  field :consumer_protection,       type: Boolean  # 是否参加消保
  field :liangpin,                  type: Boolean  # 是否是无名良品用户
  field :sign_food_seller_promise,  type: Boolean  # 卖家是否签署食品卖家承诺协议
  field :has_shop,                  type: Boolean  # 用户作为卖家是否开过店
  field :is_lightning_consignment,  type: Boolean  # 是否24小时闪电发货(实物类)
  field :has_sub_stock,             type: Boolean  # 表示用户是否具备修改商品减库存逻辑的权限
  field :magazine_subscribe,        type: Boolean  # 是否订阅了淘宝天下杂志
  field :online_gaming,             type: Boolean  # 用户是否为网游用户，属于隐私信息
  
  field :auto_repost,               type: String   # 是否受限制
  field :promoted_type,             type: String   # 有无实名认证
  field :status,                    type: String   # 状态
  field :alipay_bind,               type: String   # 有无绑定
  field :avatar,                    type: String   # 用户头像地址
  field :vip_info,                  type: String   # 用户的全站vip信息
  field :vertical_market,           type: String   # 用户参与垂直市场类型
  field :session,                   type: String   # 同步，私有會話ID  
  field :uid,                       type: String   # 用户字符串ID
  field :nick,                      type: String   # 用户昵称
  field :sex,                       type: String   # 性别
  field :type,                      type: String   # 用户类型
  
  field :created,                   type: DateTime # 用户注册时间
  field :last_visit,                type: DateTime # 最近登陆时间
  field :birthday,                  type: DateTime # 生日

  def employee_ids
    (employees.only(:employee_id).distinct(:employee_id) << ownable_id).uniq
  end

  include Sync
  include Sync::Seller
end