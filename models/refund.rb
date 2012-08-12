# -*- encoding: utf-8 -*-

class Refund
  include Mongoid::Document
  # Referenced
  belongs_to :trade,  foreign_key: 'tid'         # 交易
  belongs_to :user,   foreign_key: 'seller_nick' # 店铺
  
  field :refund_id,       type: Integer
  field :num,             type: Integer

  field :has_good_return, type: Boolean
  
  field :total_fee,       type: Float
  field :refund_fee,      type: Float
  field :payment,         type: Float

  field :tid,             type: String # 交易
  field :oid,             type: String
  field :num_iid,         type: String # 货品
  
  field :buyer_nick,      type: String
  field :seller_nick,     type: String # 店铺
  field :order_status,    type: String
  field :status,          type: String
  field :good_status,     type: String
  field :reason,          type: String
  field :desc,            type: String
  field :title,           type: String
  field :company_name,    type: String
  field :sid,             type: String
  field :address,         type: String
  
  field :created,         type: DateTime
  field :modified,        type: DateTime
  
  key :refund_id
  
  default_scope desc(:created, :modified) # 默认排序

  after_save :order_update

  def parse_status
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

  def member # 会员
    Member.where(seller_nick: seller_nick, buyer_nick: buyer_nick).last 
  end
  
  def modified_at
    modified.in_time_zone.strftime("%Y-%m-%d %H:%M:%S")
  end

  def order_update
      if trade
        order = trade.orders.where(_id: oid).last
        if status == 'CLOSED'
          order.refund_num = 0
          order.refund_fee = 0
        else
          order.refund_num = num if has_good_return
          order.refund_fee = refund_fee
        end
        order.save
      end
  end
  
  class << self
    
    def sync_create(session, start_at, end_at, page_no = 1, page_size = 100) # 賣家
      options = { # 基础参数
        :session => session, 
        :method => 'taobao.refunds.receive.get', 
        :start_modified => start_at.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S"), 
        :end_modified => end_at.end_of_day.strftime("%Y-%m-%d %H:%M:%S"),
        :fields => refund_fields, 
        :page_no => page_no,
        :page_size => page_size, 
      }
      sync_process(options)
    end

    private
      def sync_process(options, total_page=0)
        # 获取交易数据
        refunds = Topsdk.get_with(options)
        # 判断结果
        if refunds.is_a?(Hash) && refunds.has_key?('total_results')
          # 分页参数
          total_results = refunds['total_results'].to_i # 总数
              page_size = options[:page_size].to_i    # 每页数
                page_no = options[:page_no].to_i      # 页数
          # 判断记录数
          unless total_results > 0
             if total_page > 0 && page_no < total_page
               sync_process(options.merge!({:page_no => page_no}))
             else
               puts "警告：无退款记录"
             end
          else
            # 总页数
            total_page = (total_results / page_size)
            total_page += 1 if (total_results % page_size) > 0
            puts "此次抓取：共#{total_results}单。\n正在执行：#{page_no}/#{total_page}。"
            refunds = refunds['refunds']['refund'] # 退款
            refunds.each do |refund| # 循环交易
              current_refund = Refund.where(refund_id:refund['refund_id'].to_i).last
              if current_refund.nil?
                Refund.create(refund)
              elsif refund['modified'] > current_refund.modified_at
                current_refund.update_attributes(refund)
              end
            end
            # 循环
            if total_page > page_no
              sync_process(options.merge!({:page_no => (page_no+1)}), total_page)
            end
          end
        end
      end
      
      def refund_fields
       self.fields.keys.join(',')
      end
  end
end