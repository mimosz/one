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
  
  index time: 1

  default_scope desc(:time) # 默认排序

  def talk_at
    time.in_time_zone.strftime("%H时%M分") if time
  end
  
  include Sync::Msg
end