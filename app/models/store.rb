# -*- encoding: utf-8 -*-

module Store
  extend ActiveSupport::Concern
  included do
    # Fields
    field :user_id, type: Integer
    field :nick,    type: String
    field :_id,     type: String, default: -> { nick }

    after_create :get_uid
    # 店铺关系
    has_many :trades,       foreign_key: 'seller_nick' do # 交易
      def sync_ids
        where(synced_at: nil).distinct('_id')
      end
    end
    has_many :refunds,      foreign_key: 'seller_nick' do # 退款
      def recent
        desc(:created, :modified) # 默认排序
      end
    end
    has_many :items,        foreign_key: 'nick' do   # 商品
      def sync_ids
        where(synced_at: nil).distinct('_id')
      end
      def onsale
        where(approve_status: 'onsale')
      end
    end
    has_many :subusers,     foreign_key: 'seller_nick' do # 子账号
      def sync_nicks
        where(status:1).distinct('nick') # 客服
      end
    end
    has_many :chatpeers,    foreign_key: 'seller_nick' # 聊天记录
    has_many :wangwangs,    foreign_key: 'seller_nick' # 旺旺绩效
    has_many :members,      foreign_key: 'seller_nick' do # 会员
      def recent
        desc(:last_trade_time) # 默认排序
      end
    end
    has_many :rates,        foreign_key: 'seller_nick' # 店铺评分
  end

  def wangwang_id # 旺旺昵称
    'cntaobao' + nick if nick
  end

  def store_url
    'http://store.taobao.com/view_shop.htm?user_number_id=' + user_id if user_id
  end

  def get_uid
    url = store_url
    path = Nestful::Request.new(url).query_path.gsub('%25','%')
    res = Nestful::Connection.new(url).get(path)
    html = res.body.force_encoding("GBK").encode("UTF-8")
    dom = Nokogiri::HTML(html).at('p.shop-grade') # 评分节点标识
    unless dom.nil?
      uid = dom.css('a').first['href'][33..64] # 解析
      update_attributes(seller) if uid
    end
  rescue Nestful::Redirection => error
    get_uid(error.response['Location'])
  end
  
end # Store