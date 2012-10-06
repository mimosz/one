# -*- encoding: utf-8 -*-

module Sync
  module Shipping
    extend ActiveSupport::Concern

    module ClassMethods
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
               puts "警告：在同步 #{page_no}/#{total_page} 页时，出现异常。"
             end
          else
            # 总页数
            if total_page == 0
              total_page = (total_results / page_size)
              total_page += 1 if (total_results % page_size) > 0
              puts "此次抓取：共#{total_results}运单，共：#{total_page}页。"
            end
            shippings = shippings['shippings']['shipping'] # 运单
            result = { total: shippings.count, fail: [], trade_fixed: [], unchanged: [], changed: [] }
            shippings.each do |shipping| # 循环运单
              if shipping['out_sid'].nil?
                result[:fail] << shipping['order_code']
              else
                # 交易
                trade = Trade.where(_id: shipping['tid'].to_s).last
                if trade.nil?
                  trade = Trade.sync_orders( options[:session], [shipping['tid']])
                  result[:trade_fixed] << shipping['tid']
                end
                puts 
                if trade.shipping.nil? || (shipping['modified'] > trade.shipping.modified_at)
                  trade.shipping = new(shipping)
                  trade.save
                  result[:changed] << shipping['order_code']
                else
                  result[:unchanged] << shipping['order_code'] 
                end
              end
            end
            puts "第#{page_no}/#{total_page}页：共#{result[:total]}单，其中：未发货（#{result[:fail].count}），创建/变更（#{result[:changed].count}），无变化（#{result[:unchanged].count}），交易记录“补漏”（#{result[:trade_fixed].count}）。"
            # 循环
            if total_page > page_no
              sync_process(options.merge!({:page_no => (page_no+1)}), total_page)
            end
          end
        end
      end
      
      def shipping_fields
       fields.keys.join(',')
      end

    end # ClassMethods

  end # Shipping
end # Sync