# -*- encoding: utf-8 -*-

module Sync
  module Sku
    extend ActiveSupport::Concern
    
    module ClassMethods
      def sync_create(session, item_ids, limit = 40) # 在售商品
        options = { session: session, method: 'taobao.item.skus.get', fields: sku_fields }
        item_ids.each_slice(limit).to_a.each do |ids| # 每40款商品，为一组
          skus = Topsdk.get_with(options.merge!(num_iids: ids.join(',')))
          if skus.is_a?(Hash) && skus.has_key?('skus')
            process_sync(skus['skus']['sku'])
          else
            puts "Sku.sync_create============================错误"
            puts "======请======求======"
            puts options
            puts "======结======果======"
            puts skus
          end
        end
      end

      private

      def process_sync(skus)
        skus_data = {}
        skus.each do |sku|
          key = sku['num_iid']
          skus_data[key] = [] unless skus_data.has_key?(key)
          skus_data[key] << sku
        end
        item_ids = skus_data.keys
        ::Item.in(_id: item_ids).each do |item| # 商品
          skus = skus_data[item.num_iid]
          updated   = [] # 更新
          unchanged = [] # 无变化
          item.skus.each do |sku|
            skus.each do |data|
              if sku.sku_id == data['sku_id']
                  if data['modified'] > sku.modified_at
                    sku.update_attributes(data) 
                    updated << data
                  else
                    unchanged << data
                  end
              end
            end
          end
          created = skus - ( updated + unchanged ) # 新增
          unless created.empty?
            created.each do |data|
              item.skus.create(data)
            end
          end
          puts "Sku.process_sync==============（#{item.num_iid}）==============提示"
          puts "本次同步，共获取 #{skus.count} 单品，其中 新增 #{created.count}，更新 #{updated.count}，无变化 #{unchanged.count} 单品"
          skus_data.delete(item.num_iid)
        end
        unless skus_data.empty?
          puts "Sku.process_sync============================提示"
          puts skus_data
        end
      end
        
      def sku_fields
         fields.keys.join(',')
      end
      
    end # ClassMethods

  end # Sku
end # Sync