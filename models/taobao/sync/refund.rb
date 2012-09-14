# -*- encoding: utf-8 -*-

module Sync
  module Refund
    extend ActiveSupport::Concern

    module ClassMethods
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
              current_refund = where(_id: refund['refund_id'].to_s).last
              if current_refund.nil?
                create(refund)
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
        fields.keys.join(',')
      end
      
    end # ClassMethods

  end # Refund
end # Sync