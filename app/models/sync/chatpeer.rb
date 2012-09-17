# -*- encoding: utf-8 -*-

module Sync
  module Chatpeer
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(session, subusers, start_at, end_at) # 賣家
        options = { 
          session: session, 
          method: 'taobao.wangwang.eservice.chatpeers.get', 
          start_date: start_at.strftime("%Y-%m-%d %H:%M:%S"),
          end_date: end_at.strftime("%Y-%m-%d %H:%M:%S"),
        }
        subusers.each do |subuser| # 客服
          wangwang_id = subuser.wangwang_id.to_s
          current_chatpeer = {
            seller_nick: subuser.seller_nick.to_s,
            nick: subuser.nick.to_s,
            sub_id: subuser.id.to_i,
          }
          chatpeers = Topsdk.get_with(options.merge!(chat_id: wangwang_id))
          if chatpeers.is_a?(Hash) && chatpeers.has_key?('count')
            total_results = chatpeers['count'].to_i # 总数
            if total_results > 0
              chatpeers = chatpeers['chatpeers']['chatpeer']
              chatpeers = [chatpeers] if chatpeers.is_a?(Hash) # 单记录
              chatpeers.each do |chatpeer| # 聊天对象
                Msg.sync_create( current_chatpeer.merge(chatpeer), options.clone )
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
      
    end # ClassMethods

  end # Chatpeer
end # Sync