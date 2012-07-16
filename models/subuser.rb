# -*- encoding: utf-8 -*-

class Subuser # 子账号基本信息
  include Mongoid::Document
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
  
  key :sub_id
  
  def wangwang_id
    "cntaobao#{seller_nick}:#{nick}"
  end
  
  class << self
  
    def sync_create(user) # 賣家
      seller_nick = user.nick.to_s
      options = { session: user.session, method: 'taobao.sellercenter.subusers.get', nick: seller_nick }
      subusers = Topsdk.get_with(options)
      if subusers.is_a?(Hash) && subusers.has_key?('subusers') # 用戶
        subusers = subusers['subusers']['sub_user_info']
        if subusers
          subusers.each do |subuser|  # 子帳戶
            current_subuser = Subuser.where(_id: subuser['sub_id'].to_s).last # 已帳戶
            subuser['nick'].gsub!("#{user.nick}:",'')
            if current_subuser.nil?
              user.subusers.create(subuser)
            else
              current_subuser.update_attributes!(subuser)
            end
          end
        end
      else
        puts "================================请求"
        puts options
        puts "================================结果"
        puts subusers
      end
    end
  end
end