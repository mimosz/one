# -*- encoding: utf-8 -*-

module Sync
  module Seller
    extend ActiveSupport::Concern

    module ClassMethods
      def get_seller(session)
        options = { session: session , method: 'taobao.user.seller.get', fields: seller_fields }
        seller = Topsdk.get_with(options)
        if seller.is_a?(Hash) && seller.has_key?('user')
          return seller['user']
        else
          puts "Seller.get_user============================错误"
          puts seller 
        end
      end

      private
      
      def seller_fields
       (['seller_credit'] + fields.keys).join(',')
      end
      
    end # ClassMethods

    protected

    def sync_update # 更新淘宝卖家信息
      seller = Taobao::User.get_seller(session)
      update_attributes(seller) if seller
    end

  end # Seller
end # Sync