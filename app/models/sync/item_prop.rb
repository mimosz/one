# -*- encoding: utf-8 -*-

module Sync
  module ItemProp
    extend ActiveSupport::Concern
    
    module ClassMethods
      def sync_create(session, cid)
        options = { session: session, method: 'taobao.itemprops.get', cid: cid, is_sale_prop: true, fields: prop_fields }
        item_props = Topsdk.get_with(options)
        item_props = item_props['item_props']['item_prop']
        if item_props.count > 0
          item_props.each do |item_prop|
            item_prop['cid'] = cid
            item_prop['prop_values'] = item_prop['prop_values']['prop_value']
            create(item_prop)        
          end
         end
      end

      private

      def prop_fields
        'pid,name,prop_values'
      end
      
    end # ClassMethods

  end # ItemProp
end # Sync