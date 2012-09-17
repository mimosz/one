# -*- encoding: utf-8 -*-

module Sync
  module Address
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(user) # 賣家
        options = { session: user.session, method: 'taobao.logistics.address.search' }
        addresses = Topsdk.get_with(options)
        addresses = addresses['addresses']['address_result']
        addresses.each do |address|
          current_address = user.addresses.where(_id: address['contact_id'].to_s ).last
          if current_address.nil?
            user.addresses.create(address)
          elsif address.has_key?('modify_date') && address['modify_date'] > current_address.modified_at
            current_address.update_attributes!(address)
          end
        end
      end
    
    end # ClassMethods

  end # Address
end # Sync