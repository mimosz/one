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
  field :prev_max,        type: Float,   default: 0    
  field :prev_min,        type: Float,   default: 0
    
  field :price,            type: Float     # 属于这个sku的商品的价格
  field :outer_id,         type: String    # 商家设置的外部id
  field :properties,       type: String    # sku的销售属性组合字符串
  field :properties_name,  type: String    # sku所对应的销售属性的中文名字串
  field :status,           type: String    # sku状态
  field :created,          type: DateTime  # sku创建日期
  field :modified,         type: DateTime  # sku最后修改日期
  
  field :_id,              type: String, default: -> { sku_id }
  
  def range_rate
    (range_num.to_f / duration.to_f).round(1) if range_num > 0
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def prop_fields
    to_hash.keys
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

  include Sync::Sku
end