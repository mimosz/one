# -*- encoding: utf-8 -*-

One.helpers do
  def filter_meta(filter)
    { name: filter.name, price_max: filter.price_max, price_min: filter.price_min, rate_max: filter.rate_max, rate_min: filter.rate_min, item_ids: filter.item_ids}
  end

  def filter_tree(filter, node)
    key = filter._id.to_s
    unless node.has_key?(key)
      node[key] = filter_meta(filter)
      if filter.child_ids.count > 0
        children = node[key][:children] = {}
        FilterList.where(seller_nick: filter.seller_nick, :_id.in => filter.child_ids).each do |child|
          filter_tree(child, children)
        end
      end
    end
  end

  def filter_by(node, trade, order, options = {})   # 过滤列表
    node.each do |key, val|
      filter_by_ids(val, trade, order, options) 
    end
  end

  def filter_by_ids(node, trade, order, options = {})
    unless node[:item_ids].empty?
      if node[:item_ids].include?(order.num_iid) # 商家编码过滤
        filter_by_price(node, trade, order, options)
      end
    else
      filter_by_price(node, trade, order, options)
    end
  end

  def filter_by_price(node, trade, order, options = {})
    price_range = node[:price_min]..node[:price_max]
    if price_range.count > 1 # 价格过滤
      if price_range.cover?(order.price)
        filter_by_rate(node, trade, order, options)
      end
    else
      filter_by_rate(node, trade, order, options)
    end
  end

  def filter_by_rate(node, trade, order, options = {})
    rate_range = node[:rate_min]..node[:rate_max]
    if rate_range.count > 1 # 折扣过滤
      if tag_prices.has_key?(order.num_iid)
        rate = ( (order.total_fee/order.num).round(1) / tag_prices[order.num_iid].to_f * 100).round(1)
        if rate_range.cover?(rate)
          process_filtered(node, trade, order, options)
        end
        puts "二了吧：#{order.num_iid}，#{order.price}大于#{tag_prices[order.num_iid]}？？？" if rate > 100
      else
        puts "二了吧：#{order.num_iid}没有吊牌价？？？"
      end
    else
      process_filtered(node, trade, order, options)
    end
  end
  
end