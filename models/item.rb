# -*- encoding: utf-8 -*-

class Item # 商品
  include Mongoid::Document
  # Referenced
  belongs_to :user, foreign_key: 'nick'
  has_many :item_props, foreign_key: 'cid'  # 商品属性
  has_many :trades, foreign_key: 'num_iid' # 订单
  # Embedded
  embeds_many :skus

  # Fields
  field :num_iid,         type: Integer  # 商品数字id
  field :cid,             type: Integer  # 商品所属的叶子类目 id
  field :num,             type: Integer  # 商品数量
  field :sub_stock,       type: Integer  # 标识商品减库存的方式：1-拍下减库存，2-付款减库存。
  field :volume,          type: Integer  # 对应搜索商品列表页的最近成交量
  field :product_id,      type: Integer  # 宝贝所属产品的id
  # 从上架日期起，近7天的
  field :duration,        type: String,   default: '暂无'  # 周转天数
  field :range_num,       type: Integer,   default: 0  # 周转量
  # 昨日销量
  field :prev_num,        type: Integer,   default: 0  
  # 周转，价格区间
  field :range_max,       type: Float,   default: 0     
  field :range_min,       type: Float,   default: 0
  # 昨日销售，价格区间
  field :prev_max,        type: Float ,  default: 0    
  field :prev_min,        type: Float,   default: 0
  # 吊牌价
  field :fixed_price,     type: Float,   default: 0
  
  field :price,           type: Float    # 商品价格 
  field :post_fee,        type: Float    # 平邮费用
  field :express_fee,     type: Float    # 快递费用
  field :ems_fee,         type: Float    # ems费用
  
  field :pic_url,         type: String   # 商品主图片地址
  field :title,           type: String   # 商品标题
  field :detail_url,      type: String   # 商品url
  field :outer_id,        type: String   # 商家外部编码
  field :nick,            type: String   # 卖家昵称
  field :type,            type: String   # 商品类型
  field :freight_payer,   type: String   # 运费承担方式
  field :approve_status,  type: String   # 商品上传后的状态

  field :is_taobao,       type: Boolean  # 是否在淘宝显示
  
  field :list_time,       type: DateTime # 上架时间
  field :delist_time,     type: DateTime # 下架时间
  field :created,         type: DateTime # Item的发布时间
  field :modified,        type: DateTime # 商品修改时间
  field :synced_at,       type: DateTime
  
  key :num_iid
  
  index [:nick, :num_iid]
  
  scope :onsale, where(approve_status: 'onsale')
  # default_scope desc(:seven_num, :prev_num)
  
  def item_url
    "http://item.taobao.com/item.htm?id=#{num_iid}"
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def range_rate
    (range_num.to_f / duration.to_f).round(1) if range_num > 0
  end
  
  class << self

    def sync_create(session, status = :onsale, page_no = 1, page_size = 200)
      method = case status
        when :inventory  # 在仓
          'taobao.items.inventory.get'
        when :onsale  # 在售
          'taobao.items.onsale.get'
      end
      options = { session: session, method: method, page_no: page_no, page_size: page_size, fields: item_heads }
      process_sync(options)
    end
    
    def sync_update(user, start_at = 8.day.ago.to_date, end_at = 1.day.ago.to_date)
      items = user.items
      items_res = {}
      skus_res = {}
      unknown_items = [] # 未知产品
      # 预处理，商品起始值
      items.each do |item| 
        items_res[item.num_iid] = metadata unless items_res.has_key?(item.num_iid)
        date_range = start_at..end_at
        unless item.list_time.nil? # 上架
          onsale_at = item.list_time.to_date
          case
          when date_range.cover?(onsale_at)
            date_range = onsale_at..date_range.last
          when onsale_at > end_at
            date_range = "新上架"
          end
        end

        unless item.delist_time.nil? # 下架
          instock_at = item.delist_time.to_date
          if date_range.is_a?(Range) && date_range.cover?(instock_at) # 时差
            date_range = date_range.first..instock_at
          elsif instock_at < start_at
            date_range = "已下架"
          end
        end

        items_res[item.num_iid][:range] = date_range
        # 单品
        item.skus.each do |sku|
          skus_res[sku.sku_id] = metadata unless skus_res.has_key?(sku.sku_id)
        end
      end
      # 计算商品交易数
      trades = user.trades.where(pay_time: start_at.beginning_of_day..end_at.end_of_day) # 近7天
      trades.each do |trade| # 交易集合
        paid_at = trade.pay_time.to_date # 支付日期
        trade.orders.each do |order| # 订单集合
          if items_res.has_key?(order.num_iid)
            item = items_res[order.num_iid]
            if item[:range].is_a?(Range) && item[:range].cover?(paid_at)
              is_prev = (item[:range].last == paid_at) # 是否，昨日交易
              # 商品
              trade_sum(item, order.num, order.payment_avg, is_prev)
              # 单品
              sku_id = order.sku_id.to_i
              if sku_id > 0 
                if skus_res.has_key?(sku_id)
                  trade_sum(skus_res[sku_id], order.num, order.payment_avg, is_prev)
                else
                  puts "未知单品：#{order.oid}, #{order.num_iid}, #{sku_id}"
                end
              end
            end
          else
            puts "Item.sync_update=========================items_res===错误"
            puts "未知产品：#{order.oid}, #{order.num_iid}, #{order.num}"
            unknown_items << order.num_iid
          end
        end
      end
      
      # 回传商品表
      items.each do |item|
        if items_res.has_key?(item.num_iid)
          item_res = items_res[item.num_iid]
          item_res[:duration] = if item_res[:range].is_a?(Range)
            (item_res[:range].count - 1)
          else
            item_res[:range]
          end
          item_res.delete(:range)
          item.update_attributes!(item_res)
          # 单品
          item.skus.each do |sku|
            if skus_res.has_key?(sku.sku_id)
              sku_res = skus_res[sku.sku_id]
              sku_res[:duration] = item_res[:duration]
              sku.update_attributes!(sku_res)
              skus_res.delete(sku.sku_id)
            end
          end
          items_res.delete(item.num_iid)
        else
          puts "缺少商品：#{item.num_iid}"
        end
      end
      if items_res.count > 0
        puts "Item.sync_update=========================items_res===错误"
        puts items_res
      end
      if skus_res.count > 0
        puts "Item.sync_update=========================skus_res===错误"
        puts skus_res
      end
      if unknown_items.count > 0
        puts "Item.sync_items============================补失"
        sync_items(user.session, unknown_items)
      end
    end

    def sync_items(session, item_ids, limit = 20)
      result = []
      options = { session: session, method: 'taobao.items.list.get', fields: item_fields }
      puts "Item.sync_items============================提示"
      puts "本次同步， #{item_ids.count} 单"
      item_ids.each_slice(limit).to_a.each do |item| # 每20款商品，为一组
        items = Topsdk.get_with(options.merge!(num_iids: item.join(',')))
        if items.is_a?(Hash) && items.has_key?('items')
          items = items['items']['item']
          if items.count > 0
            items.each do |item|
              item['synced_at'] = Time.now
              current_item = where(num_iid: item['num_iid']).last
              if current_item.nil?
                create!(item)
              else
                current_item.update_attributes(item)
              end
              result << item['num_iid']
            end
          end
        else
          puts "Item.sync_items============================错误"
          puts "======请======求======"
          puts options
          puts "======结======果======"
          puts items
        end
      end
      Sku.sync_create(session, result) # 单品
    end

    private

    def process_sync(options, total_page = 0)
      created   = [] # 新增
      updated   = [] # 更新
      unchanged = [] # 无变化
      items = Topsdk.get_with(options)
        if items.is_a?(Hash) && items.has_key?('total_results')
          # 分页参数
          total_results = items['total_results'].to_i # 总数
          page_no = options[:page_no].to_i             # 页数
          if total_results > 0
             if total_page == 0 # 总页数
                page_size = options[:page_size].to_i    # 每页数
               total_page = (total_results / page_size)
               total_page += 1 if (total_results % page_size) > 0
             end
            items = items['items']['item']
            if items.count > 0
              items.each do |item|
                current_item = where(num_iid: item['num_iid']).last # 已有商品
                case
                 when current_item.nil?
                    created << item['num_iid'] # 新增
                    create(item)
                    item_prop = ItemProp.where(cid: item['cid'])
                    unless item_prop
                      ItemProp.sync_create(options[:session], item['cid'])
                    end
                 when item['modified'] > current_item.modified_at
                    updated << item['num_iid'] # 更新
                    # 未付款，不更新订单
                    item['synced_at'] = nil
                    current_item.update_attributes(item)
                 else
                    unchanged << item['num_iid'] # 无变化
                 end
              end
            end
            puts "Item.process_sync==============（#{page_no}/#{total_page}页）==============提示"
            puts "本次同步，共获取 #{items.count} 单，其中 新增 #{created.count}，更新 #{updated.count}，无变化 #{unchanged.count} 款"
            # 循环
            process_sync(options.merge!(page_no: (page_no + 1)), total_page) if total_page > page_no
          else
            if total_page > 0
               puts "Item.process_sync============================重试"
               process_sync(options, total_page)
             else
               puts "Item.process_sync============================错误"
               puts "======请======求======"
               puts options
               puts "======结======果======"
               puts items
             end
          end
        else
          puts "Item.process_sync============================错误"
          puts "======请======求======"
          puts options
          puts "======结======果======"
          puts items
        end
    end

    def item_heads
     'num_iid, nick, cid, modified'
    end
    
    def item_fields
     self.fields.keys.join(',')
    end
    
    def trade_sum(node, num, price, is_prev)
      node[:range_num] += num # 近7天销量
      node[:range_max] = price if price > node[:range_max].to_f
      node[:range_min] = price if node[:range_min] == 0 || price < node[:range_min].to_f
      if is_prev  # 昨日销量
        node[:prev_num] += num           
        node[:prev_max] = price if price > node[:prev_max].to_f
        node[:prev_min] = price if node[:prev_min] == 0 || price < node[:prev_min].to_f
      end
    end
    
    def metadata
      { range_num: 0, range_max: 0, range_min: 0, prev_num: 0, prev_max: 0, prev_min: 0 }
    end
  end
  include Kaminari::MongoidExtension::Criteria
  include Kaminari::MongoidExtension::Document
end