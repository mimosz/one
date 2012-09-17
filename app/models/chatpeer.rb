# -*- encoding: utf-8 -*-

class Chatpeer # 聊天对象
  include Mongoid::Document

  store_in collection: 'chatpeers'

  belongs_to :user,    foreign_key: 'seller_nick'
  belongs_to :subuser, foreign_key: 'sub_id', index: true # 客服账号
  belongs_to :member,  foreign_key: 'uid',    index: true
  embeds_many :msgs # 聊天记录

  # Fields
  field :_id,         type: String
  field :uid,         type: String  # 聊天对象用户ID
  field :date,        type: Date    # 聊天日期
  field :sub_id,      type: Integer

  field :questions_count,   type: Integer, default: 0
  field :answers_count,     type: Integer, default: 0
  field :avg_waiting_times, type: Integer, default: 0

  field :nick,        type: String
  field :seller_nick, type: String

  index seller_nick: 1, nick: 1, date: 1

  def member # 会员
    Member.where(seller_nick: seller_nick, buyer_nick: buyer_nick).last 
  end

  def qna_rate
   (answers_count.to_f/questions_count.to_f * 100).round(1) if questions_count > 0 # 未捕捉到，客人提问
  end

  def talk_at
   date.to_time.in_time_zone.strftime("%Y年%m月%d日") if date
  end

  def buyer_nick
    uid.gsub('cntaobao','')
  end

  include Sync::Chatpeer
end