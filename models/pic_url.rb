# -*- encoding: utf-8 -*-

class PicUrl
  include Mongoid::Document
  # Embedded
  embedded_in :refund_message
  
  # Fields
  
  field :url, type: String
  
end