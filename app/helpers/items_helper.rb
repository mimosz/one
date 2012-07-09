# -*- encoding: utf-8 -*-
require 'csv'

One.helpers do

  def parse_item_status(item)
    case item.approve_status
    when 'onsale'
      content_tag(:span, time_ago_in_words(item.list_time), class: 'label label-success')
    when 'instock'
      content_tag(:span, time_ago_in_words(item.delist_time), class: 'label')
    end
  end

  def items_import(csv_file)
    items = CSV.read(csv_file, 'rb:GB18030:UTF-8', headers: true, header_converters: :symbol, col_sep: ',')
      skus = {}
      items.each do |item|
        key = item[:item_id]
        skus[key] = [] unless skus.has_key?(key)
        skus[key] << item
      end
    return skus
  end

  def items_export(items, fields, file_tag)
     file_csv = File.join(PADRINO_ROOT, "public/files/items/#{Time.now.strftime('%y%m%d-%H')}-#{fields.join('-')}-#{file_tag}.csv")
     return file_csv if File.exist?(file_csv)
     unless items.empty?
       require 'csv'
       header_row = ['淘宝ID', '商家编码', 'SKU编码', '状态', '库存', '价格', '吊牌价', '周转天数', '周转量', '周转最高价', '周转最低价', '昨日销售', '昨日最高价', '昨日最低价', '名称']
       CSV.open(file_csv, "wb:GB18030", col_sep: ',') do |csv|
         csv << header_row
         items.each do |item|
           if fields.include?('item')
             csv << [ 
               "=HYPERLINK(\"#{item.item_url}\",\"#{item.num_iid}\")",
               item.outer_id, item.approve_status, '', item.num, item.price, item.fixed_price, 
               item.duration, item.range_num, item.range_max, item.range_min, 
               item.prev_num, item.prev_max, item.prev_min, 
               item.title
             ]
           end
           if fields.include?('sku')
            item.skus.each do |sku|
             props = ""
             sku.to_hash.each do | key, value |
               props << "#{key}（#{value}） "
             end
             csv << [
               sku.num_iid,
               item.outer_id,
               sku.outer_id,
               item.approve_status,
               sku.quantity,
               sku.price,
               item.fixed_price,
               sku.duration,
               sku.range_num,
               sku.range_max,
               sku.range_min,
               sku.prev_num,
               sku.prev_max,
               sku.prev_min,
               props
             ]
            end
          end
         end
       end
       return file_csv
     end
   end
end