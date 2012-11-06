# -*- encoding: utf-8 -*-

module Sync
  module ItemProp
    extend ActiveSupport::Concern
    
    module ClassMethods
      def sync_create(session, cid)
        options = { session: session, method: 'taobao.itemprops.get', cid: cid, is_sale_prop: true, fields: prop_fields }
        item_props = Topsdk.get_with(options)
        if item_props && item_props.has_key?('item_props')
          item_props = item_props['item_props']['item_prop'] 
          if item_props.count > 0
            sale_prop = { cid: cid, pid: [], name: [], prop_values: [] }
            item_props.each do |item_prop|
              sale_prop[:pid]  << item_prop['pid']
              sale_prop[:name] << item_prop['name']
              prop_values = item_prop['prop_values']['prop_value']
              if prop_values.count > 0
                prop_values.each do |prop_value|
                  sale_prop[:prop_values] << { pid: item_prop['pid'], vid: prop_value['vid'], name: prop_value['name'] }
                end
              end
            end
            create(sale_prop)
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