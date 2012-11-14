# -*- encoding: utf-8 -*-

One.helpers do

  def shipping(trade)
  if trade.shipping.nil?
    ['', '']
  else
    shipping = trade.shipping
    [shipping.company_name, shipping.out_sid]
  end
end

def export_rayban_trades(trades, date_tag, file_tag)
  file_csv = File.join(PADRINO_ROOT, "public/files/trades/#{date_tag}-#{file_tag}.csv")
  return file_csv if File.exist?(file_csv)
  unless trades.empty?
    require 'csv'
    header_row = ['订购平台', '业务人员', '客户编号', '订单编号', '数量', '单价', '商品规格', '商品代码', '金额', '是否计入库存', '订购日期', '订购人', '订购人电话', '订购人发票地址', '收货人', '收货人电话', '收货人手机', '邮编', '收货地址', '运费', '省份', '城市', '活动名称', '发货日期', '快递方式', '快递单号']
    CSV.open(file_csv, "wb:GB18030", :col_sep=>',') do |csv|
      csv << header_row
      trades.each do |trade|
        trade.orders.each do |order|
          csv << [ 
            'Rayban', 'TB', 
            trade.buyer_nick, 
            trade._id, 
            order.num, '', 
            order.price.round(2),
            order.outer_iid, 
            order.payment.round(2), 'Y', 
            trade.paid_at.strftime("%y-%m-%d"), '', '', '',
            trade.receiver_name, '', 
            trade.receiver_mobile, 
            trade.receiver_zip,
            trade.receiver_address,
            trade.post_fee.round(2),
            trade.receiver_state,
            trade.receiver_city, '', 
            (trade.sent_at.strftime("%y-%m-%d") unless trade.sent_at.nil?)
          ] + shipping(trade) if order.refund.nil?
        end
      end
    end
    return file_csv
  end
end

def export_trades(trades, date_tag, file_tag)
    file_csv = File.join(PADRINO_ROOT, "public/files/trades/#{date_tag}-#{file_tag}.csv")
    return file_csv if File.exist?(file_csv)
    unless trades.empty?
      require 'csv'
      header_row = ['订单号', '品牌特卖', '超卖', '支付时间', '货号', 'SKU', '属性', '数量', '单价', '价格', '折扣', '实付', '折扣率', '付款率', '买家', '发货时间', '退货数', '退款']
      CSV.open(file_csv, "wb:GB18030", :col_sep=>',') do |csv|
        csv << header_row
        trades.each do |t|
          t.orders.each do |o|
            csv << [ 
              "=HYPERLINK(\"http://buy.tmall.com/detail/orderDetail.htm?bizOrderId=#{o.oid}\",\"#{o.id}\")",
              t.is_brand_sale,
              o.is_oversold,
              full_date(t.pay_time),
              "=HYPERLINK(\"http://detail.tmall.com/item.htm?id=#{o.num_iid}\",\"#{o.outer_iid}\")",
              o.outer_sku_id,
              o.sku_properties_name,
              o.num, 
              o.price.round(2), 
              o.price_total,
              o.discount_fee,
              o.payment.round(2),
              o.discount_rate,
              o.payment_rate,
              "=HYPERLINK(\"http://www.taobao.com/webww/ww.php?ver=3&touid=#{t.buyer_nick}&siteid=cntaobao\",\"#{t.buyer_nick}\")",
              full_date(t.consign_time),
              o.refund_num,
              o.refund_fee,
            ]
          end
        end
      end
      return file_csv
    end
  end

  def add_tooltip(content, title)
    content_tag(:a, content, rel: 'tooltip', title: title)
  end

  def parse_sales(data, field = :num, round = 0)
    if data.has_key?(:sale) # 品牌特买
     sale = data[:sale][field].round(round)
     sale_tag = content_tag(:font, sale, style: 'color: #F89406;')
    end
    # 普通订单
    total = data[:total][field].round(round) if data.has_key?(:total)
    case
     when (sale && total)
      add_tooltip((sale + total).round(round), "#{total} + #{sale}（特买）")
     when sale
      sale_tag
     else
      total
    end
  end
  
  def parse_status(statuses, status='WAIT_BUYER_PAY')
    status = statuses[status] || trade_meta
    css = 'badge-success' if status[:num] > 0
    str = content_tag(:span, status[:num], class: ('badge ' + css.to_s), title: '数量')
    css = case
      when status[:payment] == 0 || status[:price] == 0
        ''
      when status[:payment] >= status[:price]
        'label-success'
      else
        'label-warning' 
    end
    value = status[:payment].round(2)
    str += content_tag(:span, value, class: ('label ' + css.to_s), title: '实付/价格')
    str
  end

    # options = {item: true, sku: true, status: false, timeline: {field: 'pay_time', unit: 'day'}}
def group_by(trades, options={item: true})
  result = {} # 结果集
  tag_prices(trades.only('orders.num_iid').distinct('orders.num_iid'))
  trades = trades.only(
    :receiver_state, 
    'orders.outer_iid', 
    'orders.title',
    'orders.outer_sku_id', 
    'orders.sku_properties_name',
    'orders.num_iid',
    'orders.adjust_fee', 
    'orders.discount_fee', 
    'orders.refund_num', 
    'orders.refund_fee', 
    'orders.refund_fee', 
    'orders.total_fee', 
    'orders.price', 
    'orders.payment', 
    'orders.num',
    'orders.is_oversold'
  )
  if options.has_key?(:filter_list) # 过滤列表
    trades_item_ids = [] # 宝贝ID列表（售出的）
    filter_item_ids = [] # 宝贝ID列表（已知）
    unless options[:filter_list].empty?
      result[:filter_list] = {} unless result.has_key?(:filter_list)
      filter_list = result[:filter_list]
      options[:filter_list].each do | filter |
        filter_item_ids += filter.item_ids
        filter_tree(filter, filter_list)
      end
      # options.delete(:filter_list)
    end
  end

  trades.each do |t|  
    t.orders.each do |o| 
      trade_sum(result, t, o, options) # 总数
      if result.has_key?(:filter_list)
        trades_item_ids << o.num_iid # 添加（售出的）宝贝
        filter_by(result[:filter_list], t, o, options)
      else

        if options.has_key?(:timeline)
          timeline_by(result, t, o, options)
        elsif options.has_key?(:state)
          state_by(result, t, o, options) 
        end
        
        if options.has_key?(:item)
          item_by(result, t, o, options)
        elsif options.has_key?(:sku)
          sku_by(result, t, o, options)
        end
      end
    end
  end
  if options.has_key?(:filter_list) && filter_item_ids.count > 0
    result[:unknown_ids] = (trades_item_ids - filter_item_ids).uniq  # 宝贝ID列表（未知）
  end
  return result
end
  
  def date_range(start_at, unit='day', end_at=nil)
    z = start_at.to_i # 结束时间
    a = z # 开始时间
    a += end_at.to_i unless end_at.nil? # 延长开始时间
    case unit
      when 'year'
        a.year.ago.beginning_of_year..z.year.ago.end_of_year
      when 'month'
        a.month.ago.beginning_of_month..z.month.ago.end_of_month
      when 'week'
        a.week.ago.beginning_of_week..z.week.ago.end_of_week
      else
        a.day.ago.beginning_of_day..z.day.ago.end_of_day
    end
  end
  
  def time_tag(time, range='day')
    case range
      when 'year'
        time.strftime("%y年%m月") # 月
      when 'month'
        time.strftime("%y年，第%V周") # 周
      when 'week'
        time.strftime("%m月%d日") # 日
      else
        time.strftime("%H时") # 小时
    end
  end

  def get_items(item_ids)
    Item.where(nick: user_id, :num_iid.in => item_ids).only(:tag_price)
  end

  

  def process_filtered(node, trade, order, options = {})
    trade_sum(node, trade, order)
    case
    when node.has_key?(:children)
      filter_by(node[:children], trade, order, options)
    when options.has_key?(:timeline)
      timeline_by(node, trade, order, options)
    when options.has_key?(:state)
      state_by(node, trade, order, options) 
    end

    if options.has_key?(:item)
      item_by(node, trade, order, options) 
    elsif options.has_key?(:sku)
      sku_by(node, trade, order, options)
    end
  end

  def state_by(node, trade, order, options = {})   # 时间轴
    node[:state] = {} unless node.has_key?(:state)
    node = node[:state]
    node[trade.receiver_state] = {name: trade.receiver_state, title: trade.receiver_state} unless node.has_key?(trade.receiver_state)
    node = node[trade.receiver_state]
    trade_sum(node, trade, order, options)
  end
  
  def timeline_by(node, trade, order, options = {})   # 时间轴
    node[:timelines] = {} unless node.has_key?(:timelines)
    node = node[:timelines]
    key = time_tag(trade.send(options[:timeline][:field]).in_time_zone, options[:timeline][:unit])
    node[key] = { name: key, title: key } unless node.has_key?(key)
    node = node[key]
    trade_sum(node, trade, order, options)
  end
  
  def status_by(node, trade, order)
    node[:status] = {} unless node.has_key?(:status)
    node = node[:status]
    node[order.status] = { name: order.status, title: order.status } unless node.has_key?(order.status)
    node = node[order.status]
    trade_sum(node, trade, order)
  end
  
  def item_by(node, trade, order, options)
    node[:items] = {} unless node.has_key?(:items)
    items = node[:items]
    items[order.num_iid] = { name: order.outer_iid, title: order.title } unless items.has_key?(order.num_iid)
    item = items[order.num_iid] # 货品
    trade_sum(item, trade, order, options)
    case
    when options.has_key?(:timeline)
      timeline_by(item, trade, order, options) 
    when options.has_key?(:state)
      state_by(item, trade, order, options)
    when options.has_key?(:sku)
      sku_by(item, trade, order, options)
    end
  end
  
  def sku_by(node, trade, order, options)
    node[:skus] = {} unless node.has_key?(:skus)
    skus = node[:skus]
    skus[order.sku_id] = { name: order.outer_sku_id, title: order.sku_properties_name } unless skus.has_key?(order.sku_id)
    sku = skus[order.sku_id]
    trade_sum(sku, trade, order, options)
    case
    when options.has_key?(:timeline)
      timeline_by(sku, trade, order, options) 
    when options.has_key?(:state)
      state_by(sku, trade, order, options)
    end
  end
  
  def trade_range(node, trade, order)
    unless node.has_key?(:range)
      meta = { price: order.price, payment: order.payment_avg, total_fee: order.total_avg, num: order.num }
      node[:range] = { max: meta, min: meta }
    end
    range = node[:range] 
    max = range[:min]
    min = range[:max]
    # 最大应付
    max[:total_fee] =  order.total_avg if order.total_avg > max[:total_fee].to_i
    # 最大实付
    max[:payment] =  order.payment_avg if order.payment_avg > max[:payment].to_i
    # 最大售价
    max[:price] =  order.price if order.price > max[:price].to_i
    # 最小应付
    min[:total_fee] = order.total_avg if order.total_avg < node[:total_fee].to_i
    # 最小售价
    min[:price] = order.price if order.price < min[:price].to_i
    # 最小实付
    min[:payment] = order.payment_avg if order.payment_avg < min[:payment].to_i

  end
  
  def trade_sum(node, trade, order, options = {})
    case
    when order.is_oversold
      node[:oversold] = trade_meta unless node.has_key?(:oversold)
      set = node[:oversold]
    when trade.is_brand_sale
      node[:sale] = trade_meta unless node.has_key?(:sale)
      set = node[:sale]
    else
      node[:total] = trade_meta unless node.has_key?(:total)
      set = node[:total]
    end
    
    # 订单
    set[:num] += order.num
    set[:price] += (order.price * order.num).to_f
    set[:payment] += order.payment
    set[:total_fee] += order.total_fee
    set[:adjust_fee] += order.adjust_fee
    set[:discount_fee] += order.discount_fee
    set[:refund_num] += order.refund_num
    set[:refund_fee] += order.refund_fee
    if tag_prices.has_key?(order.num_iid)
      set[:tag_price] += (tag_prices[order.num_iid] * order.num).to_f 
    end
    trade_range(node, trade, order) if options.has_key?(:range)
    status_by(node, trade, order) if options.has_key?(:status)
  end
  
  def trade_meta
    { price:0, payment:0, total_fee:0, discount_fee:0, adjust_fee:0, num:0, tag_price:0, refund_num:0, refund_fee:0 }
  end

  def tag_prices(item_ids=nil) # 吊牌价
    return @tag_prices if defined?(@tag_prices)
    tag_prices = {}
    items = get_items(item_ids)
    items.each do |item|
      tag_prices[item._id] = item.tag_price if item.tag_price > 0
    end
    @tag_prices = tag_prices
  end
  
end