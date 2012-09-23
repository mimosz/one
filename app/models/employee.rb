# -*- encoding: utf-8 -*-

class Employee # 伙计
  include Mongoid::Document
  # Referenced
  belongs_to :account
  belongs_to :employee, class_name: 'Account', foreign_key: 'employee_id'
  belongs_to :seller,   class_name: 'User',    foreign_key: 'seller_nick'

  attr_accessor :email

  # Fields
  field :employee_id,   type: String
  field :employee_name, type: String
  field :seller_nick,   type: String
  field :role,          type: String
  field :_id,           type: String, default: -> { "#{seller_nick}:#{employee_name}" }

  # Validations
  validates_presence_of :seller_nick, :role

  def email=(email)
   account = Account.where(email: email).first
   if account
      self.employee_id   = account.id
      self.employee_name = account.name
   else
      self.errors[:email] << '这伙计，还没注册呢？'
   end
  end

  def title
    case role
      when 'admin'
       '店长'
      when 'op'
       '运营'
      when 'cs'
       '客服'
    end
  end
end