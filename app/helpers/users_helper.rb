# -*- encoding: utf-8 -*-

One.helpers do
  def store_url(user_id)
    "http://store.taobao.com/view_shop.htm?user_number_id=#{user_id}"
  end
  def type_img(type)
    case type
    when 'C'
      'http://pics.taobao.com/favicon.ico'
    when 'B'
      'http://a.tbcdn.cn/p/mall/base/favicon.ico' 
    end
  end

  def rank_img(level)
    rank = [
      'red_1', 'red_2', 'red_3', 'red_4', 'red_5',
      'blue_1', 'blue_2', 'blue_3', 'blue_4', 'blue_5',
      'cap_1', 'cap_2', 'cap_3', 'cap_4', 'cap_5', 'cap_5',
      'crown_1', 'crown_2', 'crown_3', 'crown_4', 'crown_5',
    ]
    return "http://pics.taobaocdn.com/newrank/s_#{rank[(level-1)]}.gif"
  end
  
  def user_id
    return nil unless params[:user_id]
    uid = params[:user_id].force_encoding('utf-8')
    return @user_id if defined?(@user_id) && @user_id == uid
    if current_account.seller_ids.include?(uid)
      @user_id = uid
    else
      flash[:warning] = "窃取别人数据，是不道德的～～"
      puts flash[:warning]
      redirect url(:accounts, :show, account_id: current_account.id)
    end
  end
  
  def current_path?(uri)
    path_info = URI.parse(uri).path
    request.path_info =~ /^#{Regexp.escape(path_info)}/
  end
  
  def render_list(list=[], options={})
    if list.is_a? Hash
      options = list
      list = []
    end
    yield(list) if block_given?
    list_type ||= :ul
    if options[:type] 
      if ["ul", "dl", "ol"].include?(options[:type])
        list_type = options[:type].to_sym
      end
    end
    contents = ''
    list.each_with_index do |content, i|
      item_class = []
      item_content = content
      item_options = {}
      if content.is_a? Array
        item_content = content[0]
        item_options = content[1]
      end
      if item_options[:class]
        item_class << item_options[:class]
      end
      link = item_content.match(/href=(["'])(.*?)(\1)/)[2] rescue nil
      if link  && current_path?(link)
        item_class << "active" unless link == '#'
      end
      item_class = (item_class.empty?)? nil : item_class.join(" ")
      contents << content_tag(:li, item_content, class: item_class )
    end
    content_tag(list_type, contents, {class: options[:class], id: options[:id]})
  end

  def parse_rates(rates, type='rate')
    result = { timelines: [], labels: rate_labels[type], values: {}, data: {} }
    values = result[:values]
      data = result[:data]
    
    result[:labels].keys.each do |key|
      values[key] = []
        data[key] = []
    end
    # 评价原数据
    rates.each do |rate|
      date = rate.date.strftime('%-m月%-d日')
      unless result[:timelines].include?(date)
        result[:timelines] << date
        case type
        when 'rate'
          result[:labels].keys.each do |key|
            values[key] << rate.send("#{key}_rate")
              data[key] << rate.send("#{key}_diff")
          end
        end
      end
    end
    return result
  end
  
  def rate_labels
    { 
      'rate' => { 
              item: '描述相符', 
           service: '服务态度', 
             speed: '发货速度'
      },
      'service' => {
        avg_refund_days: '平均退款速度', 
            refund_rate: '近30天退款率',
         complaints_rate: '近30天投诉率', 
         punish_count: '近30天处罚数'
      }
    }
  end
end