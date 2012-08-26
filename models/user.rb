# -*- encoding: utf-8 -*-

class User
  include Mongoid::Document
  # Referenced
  belongs_to :account # 店长
  
  has_many :trades,       foreign_key: 'seller_nick' # 交易
  has_many :refunds,      foreign_key: 'seller_nick' # 退款
  has_many :items,        foreign_key: 'nick'        # 商品
  has_many :subusers,     foreign_key: 'seller_nick' # 子账号
  has_many :chatpeers,    foreign_key: 'seller_nick'
  has_many :wangwangs,    foreign_key: 'seller_nick'
  has_many :members,      foreign_key: 'seller_nick'
  has_many :rates,        foreign_key: 'seller_nick'
  has_many :filter_lists, foreign_key: 'seller_nick' # 统计过滤表
  # Embedded
  embeds_many :addresses
  embeds_one :location # 用户地址
  embeds_one :buyer_credit,  class_name: 'UserCredit'  # 买家信用
  embeds_one :seller_credit, class_name: 'UserCredit' # 卖家信用
  
  # Validations
  validates_presence_of :session
  validates_uniqueness_of :session
  validates_length_of :session, minimum: 48, maximum: 64
  # Fields
  field :user_id,                   type: Integer
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
  field :alipay_account,            type: String   # 支付宝账户
  field :alipay_no,                 type: String   # 支付宝ID
  field :avatar,                    type: String   # 用户头像地址
  field :vip_info,                  type: String   # 用户的全站vip信息
  field :email,                     type: String   # 联系人email
  field :vertical_market,           type: String   # 用户参与垂直市场类型
  field :session,                   type: String   # 同步，私有會話ID  
  field :uid,                       type: String   # 用户字符串ID
  field :nick,                      type: String   # 用户昵称
  field :sex,                       type: String   # 性别
  field :type,                      type: String   # 用户类型
  
  field :created,                   type: DateTime # 用户注册时间
  field :last_visit,                type: DateTime # 最近登陆时间
  field :birthday,                  type: DateTime # 生日
  
  field :_id, type: String, default: -> { nick }
  
  def wangwang_id # 旺旺昵称
  	"cntaobao#{nick}"
  end
  
  def store_url
    "http://store.taobao.com/view_shop.htm?user_number_id=#{user_id}"
  end

	def rate_url
	  "http://rate.taobao.com/user-rate-#{uid}.htm"
  end

  def subusers_sync
    Subuser.sync_create(self)
  end
  
  def subuser_nicks # 客服的旺旺ID
    subusers.where(status:1).distinct('nick') # 客服
  end
  
  def chatpeers_sync(start_at = nil, end_at = Date.yesterday, limit = 1, expire_at = 7.day.ago.to_date)
    if start_at.nil?
      chatpeer = chatpeers.first # 最新记录，日期倒序
      if chatpeer
        start_at = chatpeer.date.to_date.next # 新一天
      	start_at = expire_at if expire_at > start_at # 逾期
      else
        start_at = expire_at
      end
    end
    duration = (end_at - start_at).to_i # 时差
    users = subusers.where(status: 1)
    case 
      when duration >= limit # 多日
        range = start_at..end_at # 时间区间
        range.each_slice(limit).each do | day |
          day = day.last
          Chatpeer.sync_create(session, users, day.beginning_of_day, day.end_of_day)
        end
      when duration == 0 # 单日
       Chatpeer.sync_create(session, users, start_at.beginning_of_day, end_at.end_of_day)
      else
         puts "从#{start_at}到#{end_at}。"
    end
  end
  
  def wangwangs_sync(start_at = nil, end_at = Date.yesterday, limit = 1, expire_at = 7.day.ago.to_date)
    if start_at.nil?
      wangwang = wangwangs.first # 最新记录，日期倒序
      if wangwang
        start_at = wangwang.date.to_date.next # 新一天
        start_at = expire_at if expire_at > start_at # 逾期
      else
        start_at = expire_at
      end
    end
    duration = (end_at - start_at).to_i # 时差
    case 
      when duration >= limit # 多日
        range = start_at..end_at # 时间区间
        range.each_slice(limit).each do | day |
          day = day.last
          Wangwang.sync_create(self, day.beginning_of_day, day.end_of_day)
        end
      when duration == 0 # 单日
       Wangwang.sync_create(self, start_at.beginning_of_day, end_at.end_of_day)
     else
       puts "从#{start_at}到#{end_at}。"
    end
  end
  
  def trades_sync(start_at = nil, end_at = Date.today, limit = 1, expire_at = 90.day.ago.to_date) # 交易
    if start_at.nil?
      trade = trades.recent.limit(1).first # 最新记录，日期倒序
      if trade
        start_at = trade.created.to_date # 新一天
      else
        start_at = expire_at
      end
    end
    start_at = expire_at if expire_at > start_at # 逾期
    duration = (end_at - start_at).to_i # 时差
    case 
      when duration >= limit # 多日
        Trade.sync_create(session, start_at.beginning_of_day, end_at.end_of_day)
      when duration == 0 # 单日
        Trade.sync_update(session, start_at.beginning_of_day, end_at.end_of_day)
      else
       puts "从#{start_at}到#{end_at}。"
    end
  end

  def shippings_sync
    send = trades.where(:consign_time.ne => nil)
    if send.exists?
      start_at = 3.months.ago.beginning_of_day
      sent = send.where(:shipping.ne => nil)
      if sent.exists?
        start_at = sent.last.shipping.modified
      end
      Shipping.sync_create(session, start_at, Time.now)
    end
  end
  
  def orders_sync
    Trade.sync_orders(session, trade_ids)
    Item.sync_update(self)
  end

  def items_sync # 商品
    Item.sync_create(session, :onsale)
    Item.sync_create(session, :inventory)
    Item.sync_items(session, item_ids)
  end
  
  def addresses_sync # 卖家地址
    Address.sync_create(self)
  end

  def members_sync(start_at=nil, end_at=Date.today, grade=nil) # 卖家的会员
    if members.exists?
      start_at = members.recent.limit(1).first.last_trade_time if start_at.nil?
      Member.sync_update(self, start_at.beginning_of_day, end_at.end_of_day, grade)
    else
      Member.sync_create(self)
    end
  end

  def refunds_sync # 退款
    start_at = 3.months.ago.beginning_of_day
     if trades.exists?
      start_at = if refunds.exists?
        refunds.recent.first.modified
      else
        trades.where(:'orders.refund_id' => nil).last.created # 有退款的交易
      end
    end
    Refund.sync_create(session, start_at, Time.now)
  end
  
  def rates_sync # 评价，每日更新
    Rate.sync_create(self)
  end

  def sync_update # 更新淘宝卖家信息
    seller = User.get_user(session)
    if seller
      update_attributes(seller)
    else
      
    end
  end
  
  class << self

    def get_user(session)
      options = { session: session , method: 'taobao.user.get', fields: user_fields }
      seller = Topsdk.get_with(options)
      if seller.is_a?(Hash) && seller.has_key?('user')
        return seller['user']
      else
        puts "User.get_user============================错误"
        puts seller 
      end
    end
    
    private
    
    def user_fields
     (['location', 'buyer_credit', 'seller_credit'] + self.fields.keys).join(',')
    end
  end
  
  after_create :push_user_ids

  protected
  
  def push_user_ids
    account.user_ids << nick
  end
  
  private
  
  def trade_ids
    trades.where(synced_at: nil).distinct('tid')
  end

  def item_ids
    items.where(synced_at: nil).distinct('num_iid')
  end
  
  # 暂时没用
  def get_user_ids(session, nicks, limit = 40) # 在售商品
      options = { session: session, method: 'taobao.users.get', fields: 'user_id' }
      user_ids = []
      user_nicks = []
      nicks.each_slice(limit).to_a.each do |nick| # 每40款商品，为一组
        users = Topsdk.get_with(options.merge!(nicks: nick.join(',')))
        if users.is_a?(Hash) && users.has_key?('users')
          users = users['users']['user']
          users.each do |user|
            user_ids << user['user_id']
            user_nicks << nick
          end
        else
          puts "================================请求"
          puts options
          puts "================================结果"
          puts nicks
        end
      end
      if nicks.count != user_nicks.count
        puts "User.get_user_ids============================错误"
        puts (nicks - user_nicks)
      end
      return user_ids
  end
  def get_buyer_ids(session, nicks) # 在售商品
      options = { session: session, method: 'taobao.crm.members.get', page_size: 100, current_page: 1 }
      buyer_ids = []
      buyer_nicks = []
      nicks.each do |nick| # 每40款商品，为一组
        members = Topsdk.get_with(options.merge!(buyer_nick: nick))
        if members.is_a?(Hash) && members.has_key?('members')
          members = members['members']['basic_member']
          members.each do |member|
            buyer_ids << member['buyer_id']
            buyer_nicks << nick
          end
        else
          puts "================================请求"
          puts options
          puts "================================结果"
          puts nick
        end
      end
      if nicks.count != buyer_nicks.count
        puts "User.get_buyer_ids============================错误"
        puts (nicks - buyer_nicks)
      end
      return buyer_ids
  end
  
end