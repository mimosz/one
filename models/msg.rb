# -*- encoding: utf-8 -*-
require 'digest/sha1'

class Msg # 聊天消息内容
  include Mongoid::Document
  embedded_in :chatpeer

  # Fields
  field :direction,  type: Integer  # 0：客服发言，1：客户发言
  field :time,       type: DateTime # 消息日期
  field :content,    type: String   # 消息内容
  
  # default_scope desc(:time) # 默认排序

  def talk_at
   time.in_time_zone.strftime("%d日%H时%M分") if time
  end
  
  class << self
    def sync_create(chatpeer, options) # 賣家
      chatpeer_id = Digest::SHA1.hexdigest("--#{chatpeer['sub_id']}--#{chatpeer['uid']}--#{chatpeer['date']}--")
      if Chatpeer.where(_id: chatpeer_id).last
        puts "Msg.sync_create============================提示"
        puts chatpeer
      else
        unless options.has_key?(:from_id)
          options = options.merge!( 
            method: 'taobao.wangwang.eservice.chatlog.get', 
            from_id: options[:chat_id], 
            to_id: chatpeer['uid']
          )
          options.delete(:chat_id)
        end
        msgs = Topsdk.get_with(options)
        if msgs.is_a?(Hash) && msgs.has_key?('count')
          total_results = msgs['count'].to_i # 总数
          if total_results > 0
             msgs = total_results > 1 ? msgs['msgs']['msg'] : [msgs['msgs']['msg']]
             Chatpeer.create(chatpeer.merge!(_id: chatpeer_id, msgs: msgs)) #
          else
            puts "Msg.sync_create============================请求"
            puts options
            puts "================================结果"
            puts msgs
          end
        else
          puts "Msg.sync_create============================请求"
          puts options
          puts "================================结果"
          puts msgs
        end
      end
    end
  end
end