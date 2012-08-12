# -*- encoding: utf-8 -*-

One.helpers do
  def progress_bar(trade)
    date = content_tag(:code, progress_date(trade.created))
    created = content_tag(:span, '下单' + date, class: 'badge badge-success')
    content = ''
    unless trade.pay_time.nil?
      date = content_tag(:code, progress_date(trade.pay_time))
      content << content_tag(:span, '付款' + date, class: 'badge badge-success')
    end
    unless trade.consign_time.nil?
      date = content_tag(:code, progress_date(trade.consign_time))
      content << content_tag(:span, '发货' + date, class: 'badge badge-success')
    end
    unless trade.end_time.nil?
      date = content_tag(:code, progress_date(trade.consign_time))
      content << content_tag(:span, '完成' + date, class: 'badge badge-success')
    else
      content << content_tag(:span, trade.parse_status, class: 'badge badge-warning pull-right')
      created + content
    end
  end

  def progress_date(date)
    date.strftime("%m月%d日 %H时") unless date.nil?
  end

  def export_members(members, file_tag)
    file_csv = File.join(PADRINO_ROOT, "public/files/members/#{Time.now.strftime('%y%m%d-%H')}-#{file_tag}.csv")
     return file_csv if File.exist?(file_csv)
     require 'csv'
     header_row = ["会员ID", "昵称", "交易笔数", "消费金额", "平均客单", "笔数（未成交）", "金额（未成交）", "已买宝贝数", "最近一笔交易时间", "最近一笔订单号", "等级"]
     CSV.open(file_csv, "wb:GB18030", col_sep: ',') do |csv|
       csv << header_row
       members.each do |member|
           csv << [
             member.buyer_id,
             member.buyer_nick,
             member.trade_count,
             member.trade_amount,
             member.trade_pre,
             member.close_trade_count,
             member.close_trade_amount,
             member.item_num,
             member.last_trade_time,
             member.biz_order_id,
             member.grade,
           ]
       end
     end
     return file_csv
  end
end