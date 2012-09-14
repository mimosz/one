# -*- encoding: utf-8 -*-

class Taobao::Subuser # 子账号基本信息
  include Mongoid::Document

  store_in collection: 'subusers'

  belongs_to :user, foreign_key: 'seller_nick'
  # Referenced
  has_many :chatpeers, foreign_key: 'sub_id' # 聊天对象
  has_many :wangwangs, foreign_key: 'nick' # 聊天对象

  # Fields
  field :sub_id,       type: Integer # 子账号Id
  field :status,       type: Integer # 子账号当前状态
  field :is_online,    type: Integer # 是否参与分流
  field :nick,         type: String  # 子账号用户名
  field :seller_id,    type: String  # 子账号所属的主账号的唯一标识
  field :seller_nick,  type: String  # 主账号昵称
  field :full_name,    type: String  # 子账号姓名
  
  field :_id, type: String, default: -> { sub_id }
  
  index seller_nick: 1, nick: 1
  
  def wangwang_id
    "cntaobao#{seller_nick}:#{nick}"
  end

  include Sync::Subuser
end