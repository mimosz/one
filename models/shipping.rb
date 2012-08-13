# -*- encoding: utf-8 -*-

class Shipping # 訂單
  include Mongoid::Document
  # Embedded
  embedded_in :trade
  
  # Fields
  field :tid,             type: Integer
  
  field :order_code,      type: String
  field :seller_nick,     type: String # 卖家昵称
  field :buyer_nick,      type: String # 买家昵称
  field :out_sid,         type: String # 运单号.具体一个物流公司的运单号码.
  field :item_title,      type: String # 连衣花裙	货物名称
  field :receiver_name,   type: String # 收件人姓名
  field :freight_payer,   type: String # 谁承担运费
  field :seller_confirm,  type: String # 卖家是否确认发货
  field :company_name,    type: String # 物流公司名称
  field :status,          type: String # 物流订单状态
  field :type,            type: String # 物流方式
  
  field :delivery_start,  type: Date # 预约取货开始时间
  field :delivery_end	,   type: Date # 预约取货结束时间
  field :created,         type: Date # 运单创建时间
  field :modified,        type: Date # 运单修改时间

  key :out_sid
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def parse_status
    case status
      when 'CREATED'
       '待发货'
      when 'RECREATED'
       '订单重新创建'
      when 'CANCELLED'
       '订单已取消'
      when 'CLOSED'
       '订单关闭'
      when 'SENDING'
       '等候发送给物流公司'
      when 'ACCEPTING'
       '已发送给物流公司,等待接单'
      when 'ACCEPTED'
       '物流公司已接单'
      when 'REJECTED'
       '物流公司不接单'
      when 'PICK_UP'
       '物流公司揽收成功'
      when 'PICK_UP_FAILED'
       '物流公司揽收失败'
      when 'LOST'
       '物流公司丢单'
      when 'REJECTED_BY_RECEIVER'
       '对方拒签'
      when 'ACCEPTED_BY_RECEIVER'
       '对方已签收'
      else
       status
    end
  end
  
  class << self
    def sync_create(session, start_at, end_at, page_no=1, page_size=100) # 賣家
      options = { # 基础参数
        session: session, 
        method: 'taobao.logistics.orders.get', 
        start_created: start_at.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S"), 
        end_created: end_at.end_of_day.strftime("%Y-%m-%d %H:%M:%S"),
        fields: shipping_fields, 
        page_no: page_no,
        page_size: page_size, 
      }
      sync_process(options)
    end
    
    private
    
    def sync_process(options, total_page=0)
      # 获取交易数据
      shippings = Topsdk.get_with(options)
      # 判断结果
      if shippings.is_a?(Hash) && shippings.has_key?('total_results')
        # 分页参数
        total_results = shippings['total_results'].to_i # 总数
            page_size = options[:page_size].to_i    # 每页数
              page_no = options[:page_no].to_i      # 页数
        # 判断记录数
        unless total_results > 0
           if total_page > 0 && page_no < total_page
             sync_process(user, options.merge!({:page_no => page_no}))
           else
             puts "警告：无运单记录"
           end
        else
          # 总页数
          total_page = (total_results / page_size)
          total_page += 1 if (total_results % page_size) > 0
          puts "此次抓取：共#{total_results}运单。\n正在执行：#{page_no}/#{total_page}。"
          shippings = shippings['shippings']['shipping'] # 运单
          shippings.each do |shipping| # 循环运单
            # 交易
            trade = Trade.where(_id: shipping['tid'].to_s).last
            if trade.nil?
              trade = Trade.sync_orders( options[:session], [shipping['tid']])
              puts "创建了交易：#{shipping['tid']}。"
            end
            trade.shipping = new(shipping)
            trade.save
          end
          # 循环
          if total_page > page_no
            sync_process(options.merge!({:page_no => (page_no+1)}), total_page)
          end
        end
      end
    end
    
    def shipping_fields
     self.fields.keys.join(',')
    end
  end
  
end