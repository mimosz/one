# -*- encoding: utf-8 -*-

class UserCredit
  include Mongoid::Document
  embedded_in :user
  
  # Fields
  field :level,      type: Integer   # 信用等级
  field :score,      type: Integer   # 信用总分
  field :total_num,  type: Integer   # 收到的评价总条数
  field :good_num,   type: Integer   # 收到的好评总条数
  
end