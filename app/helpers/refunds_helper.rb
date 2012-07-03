# -*- encoding: utf-8 -*-

One.helpers do

  def export_refunds(refunds, date_tag, file_tag)
    file_csv = File.join(PADRINO_ROOT, "public/files/refunds/#{date_tag}-#{file_tag}.csv")
    puts file_csv
    puts "=================================="
    return file_csv if File.exist?(file_csv)
    unless refunds.empty?
      require 'csv'
      header_row = ['退款号', '订单号', '宝贝', '是否退货', '实付', '退款', '买家', '申请退款时间', '状态', '更新时间']
      CSV.open(file_csv, "wb:GB18030", :col_sep=>',') do |csv|
        csv << header_row
        refunds.each do |refund|
          csv << [ 
            "=HYPERLINK(\"http://refund.taobao.com/view_refund_detail_spirit.htm?refund_id=#{refund.refund_id}\",\"#{refund.refund_id}\"",
            "=HYPERLINK(\"http://buy.tmall.com/detail/orderDetail.htm?bizOrderId=#{refund.oid}\",\"#{refund.oid}\")",
            "=HYPERLINK(\"http://detail.tmall.com/item.htm?id=#{refund.num_iid}\",\"#{refund.title}\")",
            refund.has_good_return,
            refund.payment.round(2),
            refund.refund_fee.round(2), 
            "=HYPERLINK(\"http://www.taobao.com/webww/ww.php?ver=3&touid=#{refund.buyer_nick}&siteid=cntaobao\",\"#{refund.buyer_nick}\")",
            refund.reason,
            refund.desc,
            full_date(refund.created),
            refund.status,
            full_date(refund.modified),
          ]
        end
      end
      return file_csv
    end
  end

  def refund_status(status)
    case status
      when /WAIT_SELLER_AGREE/
        '待确认'
      when /WAIT_BUYER_RETURN_GOODS/
        '待退货'
      when /WAIT_SELLER_CONFIRM_GOODS/
        '待收货'
      when /SELLER_REFUSE_BUYER/
        '拒绝'
      when /CLOSED/
        '关闭'
      when /SUCCESS/
        '完结'
    end
  end
end