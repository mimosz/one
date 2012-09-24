# -*- encoding: utf-8 -*-
require 'securerandom'

class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  # Referenced
  has_many :employees # 伙计
  has_many :sellers,          class_name: 'User',              as: :ownable      # 自家店铺
  has_many :employer_sellers, class_name: 'Employee', foreign_key: 'employee_id' # 老板店铺
  
  attr_accessor :password, :password_confirmation

  # Fields
  field :name,             type: String
  field :email,            type: String
  
  field :mobile,           type: String
  field :tencent_qq,       type: String
  field :ali_wangwang,     type: String
  
  field :crypted_password, type: String
  field :salt,             type: String
  
  field :role,             type: String,  default: 'user'
  
  field :created_at,       type: DateTime 
  field :updated_at,       type: DateTime 
  field :paused_at,        type: DateTime # 临时冻结

  # Validations
  validates_presence_of     :email, :name
  validates_presence_of     :password,                   :if => :password_required
  validates_presence_of     :password_confirmation,      :if => :password_required
  validates_length_of       :password, within: 4..40,    :if => :password_required
  validates_confirmation_of :password,                   :if => :password_required
  validates_length_of       :email,    within: 3..100
  validates_uniqueness_of   :email,    case_sensitive: false
  validates_format_of       :email,    with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  # Callbacks
  before_save :encrypt_password, if: :password_required

  class << self

      # This method is for authentication purpose
      def authenticate(email, password)
        account = where( email: email ).first if email.present?
        account && account.password_clean == password ? account : nil
      end
    
      # This method is used by AuthenticationHelper
      def find_by_id(id)
        find(id) rescue nil
      end
    
  end

  def seller_ids
    (sellers.distinct('nick') + employer_sellers.distinct('seller_nick')).uniq
  end

  def employees_by_seller
    result = {}
    employees.each do |e|
      result[e.seller_nick] = {'运营'=>[],'客服'=>[],'店长'=>[]} unless result.has_key?(e.seller_nick)
      seller = result[e.seller_nick]
      seller[e.title] << { id: e.employee_id, name: e.employee_name }
    end
    result
  end
  
  # This method is used to retrieve the original password.
  def password_clean
   crypted_password.decrypt(salt)
  end
  
  # Password setter generates salt and crypted_password
  def password=(val)
   return if val.blank?
   update_attributes(salt: SecureRandom.hex ) if new_record?
   update_attributes(crypted_password: val.encrypt(self.salt))
  end
  
  private

  def password_required
    crypted_password.blank? || password.present?
  end
end