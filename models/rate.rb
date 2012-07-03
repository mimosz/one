# -*- encoding: utf-8 -*-

class Rate # 日店铺评价
  include Mongoid::Document
  belongs_to :user, foreign_key: 'seller_nick'

  # Fields
  
  field :item_rate,     type: Float    # 宝贝与描述相符
  field :item_diff,     type: Float,   default: 0
  field :service_rate, type: Float    # 服务态度
  field :service_diff, type: Float,   default: 0
  field :speed_rate,    type: Float    # 发货速度
  field :speed_diff,    type: Float,   default: 0

  field :avg_refund_days, type: Float    # 平均退款速度
  field :avg_refund_diff, type: Float,   default: 0
  field :refund_rate,      type: Float    # 退款率
  field :refund_diff,      type: Float,   default: 0
  field :complaints_rate, type: Float    # 投诉率
  field :complaints_diff, type: Float,   default: 0
  field :punish_count,     type: Integer  # 处罚数
  field :punish_diff,      type: Float,   default: 0

  field :seller_nick,      type: String
  field :date,             type: Date
  
  default_scope asc(:date)
  scope :date_at, ->(date) { where(:date => date) }
  class << self

    def sync_create(user) # 评价，每日更新
      conditions = {
        date: Date.today.to_time,
        seller_nick: user.nick.to_s,
      }
      return false if Rate.where(conditions).last
      rates = seller_rate(user.uid) 
      services = seller_serv(user.user_id) 
      conditions.merge!(rates)
      conditions.merge!(services)
      Rate.create(conditions)
    end

    private

    def seller_rate(uid) # 店铺评分
      url = "http://rate.taobao.com/user-rate-#{uid}.htm"
      html =  Nestful.get(url).force_encoding("GBK").encode("UTF-8")
      dom = Nokogiri::HTML(html).at('div#sixmonth') # 解析成XPath
      rates = dom.css('em.count')
      percents = dom.css('strong.percent')
      return {
        # 宝贝与描述相符
        item_rate: get_rate(rates[0]),  
        item_diff: get_rate_diff(percents[0]),  
        # 服务态度
        service_rate: get_rate(rates[1]),  
        service_diff: get_rate_diff(percents[1]),  
        # 发货速度
        speed_rate: get_rate(rates[2]),  
        speed_diff: get_rate_diff(percents[2]),  
      }
    end

    def seller_serv(user_id) # 店铺服务
      url = 'http://rate.taobao.com/ShopService4C.htm'
      params = {'userNumId' => user_id, 'callback' => ''}
      json =  Nestful.get(url, params: params).force_encoding("GBK").encode("UTF-8")
      json =  JSON.parse(json)  # 解析成JSON
      avg_refund = json['avgRefund']
      refund_rate = json['ratRefund']
      complaints = json['complaints']
      punish = json['punish']
      return {
        # 平均退款速度
        avg_refund_days: avg_refund['localVal'],
        avg_refund_diff: get_serv_diff(avg_refund),   # 
        # 退款率
        refund_rate: refund_rate['localVal'], 
        refund_diff: get_serv_diff(refund_rate),   #
        # 投诉率
        complaints_rate: complaints['localVal'],
        complaints_diff: get_serv_diff(complaints),   # 
        # 处罚数
        punish_count:punish['localVal'], 
        punish_diff: get_serv_diff(punish),   #
      }      
    end

    def get_serv_diff(json) # 
      (json['localVal'].to_f - json['indVal'].to_f).round(2)
    end

    def get_rate(dom)
      dom['title'].gsub('分','')
    end

    def get_rate_diff(dom) # 解析百分比，大于、小于
      style = dom['class']
      val = dom.text.gsub('%','')
      num = case
        when style.include?("normal")
          0
        when style.include?("lower")
          "-#{val}"
        when style.include?("over")
          "+#{val}"
      end
      num.to_f
    end
  end
end