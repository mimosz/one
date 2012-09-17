# -*- encoding: utf-8 -*-

module Sync
  module Member
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(user, options = {}, current_page=1, page_size=100) # 賣家
        seller_id   = user.user_id
        seller_nick = user.nick
        session     = user.session
        options = { # 基础参数
          session: session, 
          method: 'taobao.crm.members.get', 
          current_page: current_page,
          page_size: page_size, 
        }.merge!(options)
        # 执行
        process_sync(seller_id, seller_nick, options)
      end

      def sync_update(user, start_at, end_at, grade=nil, current_page=1, page_size=100) # 賣家
          seller_id   = user.user_id
          seller_nick = user.nick
          session     = user.session
          options = { # 基础参数
            session: session, 
            method: 'taobao.crm.members.increment.get', 
            start_modify: start_at.strftime("%Y-%m-%d %H:%M:%S"), 
            end_modify: end_at.strftime("%Y-%m-%d %H:%M:%S"), 
            current_page: current_page,
            page_size: page_size, 
          }
          # 会员等级
          options = {grade: grade}.merge!(options) unless grade.nil?
          # 执行
          process_sync(seller_id, seller_nick, options)
      end

      private

      def process_sync(id, nick, options, total_page = 0)
        result = []
        # 获取交易数据
        members = Topsdk.get_with(options)
        # 判断结果
        if members.is_a?(Hash) && members.has_key?('total_result')
          # 分页参数
          total_result = members['total_result'].to_i # 总数
          current_page = options[:current_page].to_i             # 页数
          # 判断记录数
          if total_result > 0
             if total_page == 0 # 总页数
                page_size = options[:page_size].to_i    # 每页数
               total_page = (total_result / page_size)
               total_page += 1 if (total_result % page_size) > 0
             end
             members = members['members']['basic_member'] # 
             if members.count > 0
               members.each do |member| # 循环
                 member['seller_nick'] = nick
                 member['seller_id']   = id
                 member['group_ids']   = member['group_ids'].to_s.split('|')
                 member_id = "#{id}-#{member['buyer_id']}"
                 # 已有
                 current_member = where(_id: member_id).last
                 if current_member.nil?
                    result << member
                    create(member)        
                 elsif member['last_trade_time'].to_time > current_member.last_trade_time
                    result << member
                    member['synced_at'] = nil
                    current_member.update_attributes(member)
                 end
               end
             end
             if members.count != result.count
               puts "Member.process_sync============================错误"
               puts (members - result)
             end 
             # 循环
             process_sync(id, nick, options.merge!(current_page: (current_page + 1)), total_page) if total_page > current_page
          else
            if total_page > 0
               puts "Member.process_sync============================重试"
               process_sync(id, nick, options, total_page)
             else
               puts "Member.process_sync============================错误"
               puts "======请======求======"
               puts options
               puts "======结======果======"
               puts members
             end
          end
        else
          if total_page > 0
           puts "Member.process_sync============================重试"
           process_sync(id, nick, options, total_page)
          else
           puts "Member.process_sync============================错误"
           puts "======请======求======"
           puts options
           puts "======结======果======"
           puts members
          end
        end
      end
    
    end # ClassMethods

  end # Member
end # Sync