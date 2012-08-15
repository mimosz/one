# -*- encoding: utf-8 -*-


class Sku # 产品
  include Mongoid::Document
  # Embedded
  embedded_in :item

  # Fields
  field :sku_id,          type: Integer   # sku的id
  field :num_iid,         type: Integer   # sku所属商品数字id
  field :quantity,        type: Integer   # 属于这个sku的商品的数量
  
  field :duration,        type: Integer,   default: 0  # 从上架日期起，近7天的实际天数
  field :range_num,       type: Integer,   default: 0  # 从上架日期起，近7天的销量
  field :prev_num,        type: Integer,   default: 0  # 昨日销量
  
  field :range_max,       type: Float,   default: 0     
  field :range_min,       type: Float,   default: 0
  field :prev_max,        type: Float ,  default: 0    
  field :prev_min,        type: Float,   default: 0
    
  field :price,            type: Float     # 属于这个sku的商品的价格
  field :outer_id,         type: String    # 商家设置的外部id
  field :properties,       type: String    # sku的销售属性组合字符串
  field :properties_name,  type: String    # sku所对应的销售属性的中文名字串
  field :status,           type: String    # sku状态
  field :created,          type: DateTime  # sku创建日期
  field :modified,         type: DateTime  # sku最后修改日期
  
  field :_id, type: String, default: -> { sku_id }
  
  def range_rate
    (range_num.to_f / duration.to_f).round(1) if range_num > 0
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def to_hash
    return nil if properties_name.nil?
    	properties_map = {}
    	properties_name.split(';').each do |prop|
    	  prop = prop.split(':') # 切割
    	  if prop.count == 4
         properties_map[prop[2]] = prop[3]
      	end
    	end
    	properties_map
  end

   def check_by_props(props)
    props_name = to_hash
      if props[:color] == props_name['颜色分类']
        return case props[:size]
        when props_name['尺码']
          props_name
        when props_name['鞋码']
          props_name
        when props_name['服装尺码']
          props_name
        when props_name['运动服尺寸'] 
          props_name
        else
          false
        end
      end
    return false
   end
  
  class << self
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
      Item.any_in(num_iid: item_ids).each do |item| # 商品
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
       self.fields.keys.join(',')
    end
  end
end