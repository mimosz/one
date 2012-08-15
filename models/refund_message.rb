# -*- encoding: utf-8 -*-

class RefundMessage
  include Mongoid::Document
  # Embedded
  embedded_in :refund
  embeds_many :pic_urls
  
  # Fields
  field :id,            type: Integer
  field :refund_id,     type: Integer
  field :owner_id,      type: Integer
  
  field :owner_role,    type: String
  field :owner_nick,    type: String
  field :content,       type: String
  field :message_type,  type: String
  
  field :created,       type: DateTime
  
  field :_id, type: String, default: -> { id }
  
  class << self
    
    def sync_create(session, refund, page_no=1, page_size=100) # 賣家
      options = { # 基础参数
        :session => session, 
        :method => 'taobao.refund.messages.get', 
        :refund_id => refund.refund_id, 
        :fields => messages_fields, 
        :page_no => page_no,
        :page_size => page_size, 
      }
      sync_process(session, refund, options)
    end

    private
      def sync_process(session, refund, options, total_page=0)
        # 获取交易数据
        messages = Topsdk.get_with(options)
        # 判断结果
        if messages.is_a?(Hash) && messages.has_key?('total_results')
          # 分页参数
          total_results = messages['total_results'].to_i # 总数
              page_size = options[:page_size].to_i    # 每页数
                page_no = options[:page_no].to_i      # 页数
          # 判断记录数
          unless total_results > 0
             if total_page > 0 && page_no < total_page
               sync_process(session, refund, options.merge!({:page_no => page_no}))
             else
               puts "警告：无交易记录"
             end
          else
            # 总页数
            total_page = (total_results / page_size)
            total_page += 1 if (total_results % page_size) > 0
            puts "此次抓取：共#{total_results}单。\n正在执行：#{page_no}/#{total_page}。"
            messages = messages['refund_messages']['refund_message'] # 退款
            messages.each do |message| # 循环交易
              message['pic_urls'] = message['pic_urls']['pic_url'] if message.has_key?('pic_urls')
              refund.messages.create!(message)
            end
            # 循环
            if total_page > page_no
              sync_process(session, refund, options.merge!({:page_no => (page_no+1)}), total_page)
            end
          end
        end
      end
      
      def messages_fields
       self.fields.keys.join(',')
      end
  end
  
end