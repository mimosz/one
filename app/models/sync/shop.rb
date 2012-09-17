# -*- encoding: utf-8 -*-

module Sync
  module Shop
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(session, seller_nick)
        options = { session: session, method: 'taobao.shop.get', nick: seller_nick, fields: shop_fields}
        shop = Topsdk.get_with(options)
        if shop.is_a?(Hash) && shop.has_key?('shop')
          shop = shop['shop']
          current_shop = where(_id: shop['sid'].to_s ).last
          if current_shop.nil?
            create(shop)
          elsif shop.has_key?('modified') && (shop['modified'] > current_shop.modified_at)
            current_shop.update_attributes!(shop)
          end
        else
          logger.error '////-- Shop.sync_create --////'
          logger.error '/*'
          logger.error options.to_s
          logger.error '------------------------------'
          logger.error shop.to_s
          logger.error '*/'
        end
      end

      private

      def shop_fields
        fields.keys.join(',')
      end
      
    end # ClassMethods

  end # Shop
end # Sync