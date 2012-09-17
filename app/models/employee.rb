# -*- encoding: utf-8 -*-

class Employee # 伙计
  include Mongoid::Document
  # Referenced
  embedded_in :account

  attr_accessor :employee, :seller

  # Fields
  field :employee_id,   type: String
  field :employee_name, type: String
  field :seller_nick,   type: String
  field :role,          type: String
  field :_id,           type: String, default: -> { employee_id }

  def employee=(account)
   return unless account.is_a?(Account)
   self.employee_id   = account.id
   self.employee_name = account.name
  end

  def seller=(user)
   return unless user.is_a?(User)
   self.seller_nick = user.nick
  end
end