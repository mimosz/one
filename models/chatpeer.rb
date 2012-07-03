# -*- encoding: utf-8 -*-

class Chatpeer # 聊天对象
  include Mongoid::Document
  belongs_to :subuser, foreign_key: 'sub_id' # 客服账号
  belongs_to :user, foreign_key: 'seller_nick'
  embeds_many :msgs # 聊天记录

  # Fields
  field :_id,         type: String
  field :uid,         type: String  # 聊天对象用户ID
  field :date,        type: Date    # 聊天日期
  field :sub_id,      type: Integer
  field :nick,        type: Integer
  field :seller_nick, type: String
  
  class << self
    
    def sync_create(session, subusers, start_at, end_at) # 賣家
      options = { 
        session: session, 
        method: 'taobao.wangwang.eservice.chatpeers.get', 
        start_date: start_at.strftime("%Y-%m-%d %H:%M:%S"),
        end_date: end_at.strftime("%Y-%m-%d %H:%M:%S"),
      }
      subusers.each do |subuser| # 客服
        wangwang_id = subuser.wangwang_id.to_s
        new_chatpeer = {
          seller_nick: subuser.seller_nick.to_s,
          nick: subuser.nick.to_s,
          sub_id: subuser.id.to_i,
        }
        chatpeers = Topsdk.get_with(options.merge!(chat_id: wangwang_id))
        if chatpeers.is_a?(Hash) && chatpeers.has_key?('count')
          total_results = chatpeers['count'].to_i # 总数
          if total_results > 0
            chatpeers = chatpeers['chatpeers']['chatpeer']
             if chatpeers.is_a?(Array) # 多记录
               chatpeers.each do |chatpeer| # 聊天对象
                  chatpeer = chatpeer.merge!(new_chatpeer)
                  Msg.sync_create(chatpeer, options.clone)
               end
             end
             if chatpeers.is_a?(Hash) # 单记录
                chatpeer = chatpeers.merge!(new_chatpeer)
                Msg.sync_create(chatpeer, options.clone)
             end
          else
            puts "================================请求"
            puts options
            puts "================================结果"
            puts chatpeers
          end
        else
          puts "================================请求"
          puts options
          puts "================================结果"
          puts chatpeers
        end
      end
    end
  end
end