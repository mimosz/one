# -*- encoding: utf-8 -*-

class Receiver
  include Mongoid::Document
  embedded_in :member

  # Fields
  field :receiver_address,  type: String
  field :receiver_city,     type: String
  field :receiver_district, type: String
  field :receiver_mobile,   type: String
  field :receiver_name,     type: String
  field :receiver_state,    type: String 
  field :receiver_zip,      type: String
  field :mobile_carrier,    type: String
  field :mobile_network,    type: String

end