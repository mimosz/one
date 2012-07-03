# -*- encoding: utf-8 -*-

One.helpers do
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