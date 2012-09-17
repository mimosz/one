# -*- encoding: utf-8 -*-

class Wangwang # 客服
  include Mongoid::Document

  store_in collection: 'wangwangs'

  belongs_to :subuser, foreign_key: 'nick' # 客服账号
  belongs_to :user,    foreign_key: 'seller_nick'

  # Fields
  field :date,               type: Date    # 聊天日期
  field :reply_num,          type: Integer, default: 0
  field :non_reply_num,      type: Integer, default: 0
  field :avg_waiting_times,  type: Integer, default: 0
  field :online_times,       type: Integer, default: 0
  field :loginlogs_count,    type: Integer, default: 0
  field :questions_count,    type: Integer, default: 0
  field :answers_count,      type: Integer, default: 0
  field :num,                type: Integer, default: 0
  field :price,              type: Float,   default: 0
  field :payment,            type: Float,   default: 0
  field :non_reply_customId, type: String
  field :seller_nick,        type: String
  field :buyer_nicks,        type: Array,   default: []
  field :reply_nicks,        type: Array,   default: []
  field :non_reply_nicks,    type: Array,   default: []
  
  default_scope desc(:date, :subuser_id)
  
  def buyer_count
    buyer_nicks.count
  end

  def qna_rate
   (answers_count.to_f/questions_count.to_f * 100).round(1) if questions_count > 0 # 未捕捉到，客人提问
  end
  
  def pay_rate
    (buyer_count/reply_num.to_f*100).round(2) if buyer_count > 0
  end

  def price_avg
    (payment.to_f/num.to_f).round(2) if payment > 0
  end
	
	def online_hours
	  (online_times.to_f/60/60).round(1) if online_times > 0
	end

  def talk_at
   date.to_time.in_time_zone.strftime("%Y-%m-%d") if date
  end
  
  include Sync::Wangwang
end