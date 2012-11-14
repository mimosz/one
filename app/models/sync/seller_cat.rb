# -*- encoding: utf-8 -*-

module Sync
  module SellerCat
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(session, seller_nick)
        options = { session: session, method: 'taobao.sellercats.list.get', nick: seller_nick }
        seller_cats = Topsdk.get_with(options)
        if seller_cats.is_a?(Hash) && seller_cats.has_key?('seller_cats')
          seller_cats = seller_cats['seller_cats']['seller_cat']
          ids = seller_cat_ids(seller_nick)
          seller_cats.each do |seller_cat|
            if ids.include?(seller_cat['cid'])
              where(seller_nick: seller_nick, cid: seller_cat['cid']).update(seller_cat)
            else
              seller_cat['seller_nick'] = seller_nick
              create(seller_cat)
            end
          end
        else
          logger.error '////-- SellerCat.sync_create --////'
          logger.error '/*'
          logger.error options.to_s
          logger.error '-----------------------------------'
          logger.error seller_cats.to_s
          logger.error '*/'
        end
      end

      private

      def seller_cat_ids(seller_nick)
        where(seller_nick: seller_nick).only(:_id).distinct(:_id)
      end
    
    end # ClassMethods

  end # SellerCat
end # Sync