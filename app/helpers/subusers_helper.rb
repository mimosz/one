# -*- encoding: utf-8 -*-

One.helpers do
  def ww_link(nick)
    link_to( ww_image(nick) + nick, "http://www.taobao.com/webww/ww.php?ver=3&touid=#{nick}&siteid=cntaobao&status=2&charset=utf-8", target: '_blank')
  end

  def chatlog_link(nick, title='聊天记录')
    link_to( title + "<i class='icon-comment'></i>" , url( :chatpeers, :show, user_id: user_id, uid: nick ), class: 'btn btn-mini', target: '_blank')
  end
  
  def ww_image(nick)
    image_tag("http://amos.alicdn.com/realonline.aw?v=2&uid=#{nick}&site=cntaobao&s=2&charset=utf-8")
  end
  
  def ww_status(num) # 子帳戶狀態
    case num
      when 1
       "正常"
      when -1
       "删除"
      when 2
       "冻结"
    end
  end
  
  def ww_online(num) # 旺旺分流
    case num
    when 1
     "不参与"
    when 2
      "参与"
    end
  end
  
  def full_date(date, divider = ' ')
    date.strftime("%Y年") +  divider + short_date(date) + divider + full_time(date) unless date.nil?
  end
  
  def short_date(date)
    date.strftime("%m月%d日") unless date.nil?
  end

  def full_time(time, divider = ' ')
    time.strftime("%H时#{divider}%M分:%S秒") unless time.nil?
  end
  
  def short_time(time)
    time.strftime("%H时%M分") unless time.nil?
  end
  
  def date_tag(range, divider = '-') # 判别是单日，还是时段。
    now = Time.now
    now_at = now.to_date
    start_at = range.first.to_date
    end_at = range.last.to_date
    case start_at
    when now_at # 当天
      now.strftime("%y%m%d#{divider}%H")
    when end_at # 单日
      start_at.to_s
    else # 多日
      start_at.to_s + divider + end_at.to_s
    end
  end
  
  def export_wangwangs(wangwangs, date_tag, file_tag)
    file_csv = File.join(PADRINO_ROOT, "public/files/wangwangs/#{date_tag}-#{file_tag}.csv")
    return file_csv if File.exist?(file_csv)
    unless wangwangs.empty?
      require 'csv'
      header_row = ['旺旺', '购买', '接待', '转化率', '实付', '商品', '客单价', '未接待', '平均等待时长', '在线时间', '登录次数', '未接待列表', '购买列表', '接待列表']
      divider_date = nil
      CSV.open(file_csv, "wb:GB18030", :col_sep=>',') do |csv|
        csv << header_row
        wangwangs.each do |w|
          buyer_count = w.buyer_nicks.count.to_f
    			pay_rate = (buyer_count/w.reply_num.to_f*100).round(2) if buyer_count > 0
    			payment = w.payment.round(2).to_f
    			avg_price = (payment/w.num.to_f).round(2) if payment > 0
    			if divider_date != w.date
    			  divider_date = w.date #
    			  csv << [divider_date, '', '', '', '', '', '', '', '', '', '', '', '', ''] # 日期间隔
    			end
          csv << [ 
            w.nick, # 旺旺
            buyer_count, # 购买
            w.reply_num, # 接待
            "#{pay_rate}%", # 转化率
            payment, # 实付
            w.num, # 商品
            avg_price, # 客单价
            w.non_reply_num, # 未接待
            w.avg_waiting_times, # 平均等待时长
            w.online_times, # 在线时间
            w.loginlogs_count, # 登录次数
            w.non_reply_nicks.join('，'), # 未接待列表
            w.buyer_nicks.join('，'), # 购买列表
            w.reply_nicks.join('，') # 接待列表
          ]
        end
      end
      return file_csv
    end
  end
end