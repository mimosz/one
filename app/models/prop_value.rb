# -*- encoding: utf-8 -*-

class PropValue
  include Mongoid::Document
  embedded_in :item_prop

  # Fields
  field :vid,   type: Integer # 属性值ID
  field :pid,   type: Integer # 属性ID
  field :name,  type: String  # 属性值
  field :_id,   type: String, default: -> { name }
  
  def properties
    "#{pid}:#{vid}"
  end
end