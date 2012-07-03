# -*- encoding: utf-8 -*-
require 'digest/sha1'

class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  # Referenced
  belongs_to :account, foreign_key: 'created_by' # 店长
  
  has_many :users # 店铺
  has_many :accounts, class_name: 'Account', foreign_key: 'created_by'  # 店员
  
  attr_accessor :password, :password_confirmation

  # Fields
  field :name,             type: String
  field :email,            type: String
  
  field :mobile,           type: String
  field :tencent_qq,       type: String
  field :ali_wangwang,     type: String
  
  field :crypted_password, type:String
  field :salt,             type: String
  
  field :role,             type: String
  field :created_by,       type: String
  
  field :created_at,       type: DateTime 
  field :updated_at,       type: DateTime 
  field :disabled_at,      type: DateTime
  
  field :user_ids,         type: Array,   default: []

  # Validations
  validates_presence_of     :email, :name
  validates_presence_of     :password,                   :if => :password_required
  validates_presence_of     :password_confirmation,      :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password,                   :if => :password_required
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email,    :case_sensitive => false
  validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  # Callbacks
  before_save :encrypt_password, :if => :password_required

  class << self
    
      # This method is for authentication purpose
      def authenticate(email, password)
        account = first(:conditions => { :email => email }) if email.present?
        account && account.password_clean == password ? account : nil
      end
    
      # This method is used by AuthenticationHelper
      def find_by_id(id)
        find(id) rescue nil
      end
    
  end
  
  # This method is used to retrieve the original password.
  def password_clean
   crypted_password.decrypt(salt)
  end
  
  # Password setter generates salt and crypted_password
  def password=(val)
   return if val.blank?
   update_attributes(salt: Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--")) if new?
   update_attributes(crypted_password: val.encrypt(self.salt))
  end
  
  private

  def password_required
    crypted_password.blank? || self.password.present?
  end
end