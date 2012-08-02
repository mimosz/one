# -*- encoding: utf-8 -*-
require 'digest/sha1'
require 'digest/bubblebabble'

class Msg # 聊天消息内容
  include Mongoid::Document
  embedded_in :chatpeer

  # Fields
  field :direction,  type: Integer  # 0：客服发言，1：客户发言
  field :time,       type: DateTime # 消息日期
  field :content,    type: String   # 消息内容
  
  # default_scope desc(:time) # 默认排序

  def talk_at
   time.in_time_zone.strftime("%H时%M分") if time
  end
  
  class << self
    def sync_create(chatpeer, options) # 賣家
      chatpeer_id = "#{chatpeer[:sub_id]}-#{chatpeer['uid']}-#{chatpeer['date'].to_time.to_i}"
      chatpeer_id = Digest.bubblebabble(Digest::SHA1::hexdigest(chatpeer_id)[8..12]) 
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
             msgs = msgs['msgs']['msg']
             msgs = [msgs] if msgs.is_a?(Hash) # 单记录
             chatpeer.merge!(parse_msgs(msgs))
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

    private

    def parse_msgs(msgs)
      # 定义基础变量
      questions = 0 # 提问数
      answers = 0 # 答复数

      avg_waiting_times = 0 # 平均,等待时间
      asked_at = 0 # 发起，提问时间
      msgs.each do |msg|
        talked_at = msg['time'].to_time.to_i
        case msg['direction'].to_i
        when 1
          if asked_at == 0 || asked_at > talked_at
            asked_at = talked_at   
          end
          questions += 1 # 累加，提问数
        when 0
          if asked_at > 0
            avg_waiting_times += (talked_at - asked_at)
            asked_at = 0 # 清除，提问时间
          end
          answers += 1 # 累加，答复数
        end
      end
      { questions_count: questions, answers_count: answers, avg_waiting_times: avg_waiting_times }
    end
  end
end