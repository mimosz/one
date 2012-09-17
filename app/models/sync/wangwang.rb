# -*- encoding: utf-8 -*-

module Sync
  module Wangwang
    extend ActiveSupport::Concern

    module ClassMethods
      def sync_create(user, start_at, end_at, limit = 30) # 賣家
        puts "==============警惕淘宝作恶================="
        puts "服务提供时间（7:00:00-24:00:00）"
        puts "==========================================="
        options = { 
          session:user.session,  
          start_date: start_at.strftime("%Y-%m-%d %H:%M:%S"),
          end_date: end_at.strftime("%Y-%m-%d %H:%M:%S"),
        }
        user.subusers.sync_nicks.each_slice(limit).to_a.each do |subusers| # 分组
          # 淘宝数据
          wangwang_ids = nick_to_wws(subusers, user.nick).join(',') # 转换格式
          methods.each do |method|
            puts "Wangwang。sync_create============================#{method}"
            results = Topsdk.get_with(options.merge!({method: method, service_staff_id: wangwang_ids}))
            results = get_data(results)
            if results.is_a?(Array) # 多记录
              results.each do |result|
                set_wangwang(result, start_at)
              end
            end
            
            if results.is_a?(Hash) # 单记录
              set_wangwang(results, start_at)
            end
          end
         # 交易数据
         wangwangs = where(date: start_at, seller_nick: user.nick, :nick.in => subusers) # 已有记录
         unless wangwangs.empty?
          wangwangs.each do |wangwang|
            # 元数据
            meta = {
              non_reply_nicks: [],
              reply_nicks: [],
              questions_count: 0,
              answers_count: 0,
              avg_waiting_times: 0,
              reply_num: 0,
              non_reply_num: 0
            }
            # 交易记录
            trades = []
            # 聊天对象
            chatpeers = Chatpeer.where(date: start_at, seller_nick: wangwang.seller_nick, nick: wangwang.nick)
            unless chatpeers.empty?
              chatpeers.each do |chatpeer|
                meta[:answers_count] += chatpeer.answers_count
                meta[:questions_count] += chatpeer.questions_count
                meta[:avg_waiting_times] += chatpeer.avg_waiting_times
                if chatpeer.answers_count > 0 # 答复数
                  meta[:reply_nicks] << chatpeer.uid
                else
                  meta[:non_reply_nicks] << chatpeer.uid
                end
              end
              # 未接待的客人
              unless meta[:non_reply_nicks].empty?
                meta[:non_reply_nicks] = ww_to_nicks(meta[:non_reply_nicks]).uniq
                meta[:non_reply_num] = meta[:non_reply_nicks].count
              end
              # 接待的客人
              unless meta[:reply_nicks].empty?
                meta[:reply_nicks] = ww_to_nicks(meta[:reply_nicks]).uniq
                meta[:reply_num] = meta[:reply_nicks].count
                # 加权平均
                meta[:avg_waiting_times] = (meta[:avg_waiting_times] / meta[:reply_num].to_f).round
                # 通过接待的客人昵称，获取交易记录
                trades = user.trades.where( pay_time: start_at..end_at, :buyer_nick.in => meta[:reply_nicks])
              end
              buyers = trades_sum(trades) # 买家信息
              wangwang.update_attributes(buyers.merge(meta))
            end
          end
         end
        end
      end
      
      private
      
      
      def nick_to_wws(nicks, seller_nick)
        ww_tag = "cntaobao#{seller_nick}:"
        (ww_tag << nicks.join(",#{ww_tag}")).split(',') # 旺旺标签
      end
      
      def trades_sum(trades)
        buyers = {num: 0, price: 0, payment: 0, buyer_nicks: []}
        unless trades.empty?
          trades.each do |trade|
            trade.orders.each do |order|
              buyers[:num]     += order.num.to_i
              buyers[:price]   += order.price.to_f
              buyers[:payment] += order.payment.to_f
            end
            buyers[:buyer_nicks] << trade.buyer_nick
          end
        end
        buyers[:buyer_nicks].uniq!
        buyers
      end
      
      def ww_to_nicks(wangwang_ids)
        if wangwang_ids.is_a?(Array) && wangwang_ids.count > 0
          wangwang_ids.join(',').gsub('cntaobao','').split(',') 
        else
          []
        end
      end
      
      def set_wangwang(result, date)
        subuser_opt = get_subuser(result)
        current_wangwang = where({date:date}.merge(subuser_opt)).last # 已有记录
        if current_wangwang.nil?
          Wangwang.create(result.merge!({date:date}.merge(subuser_opt)))
        else
          current_wangwang.update_attributes(result)
        end
      end
      
      def get_subuser(result)
        ww_id = if result.has_key?('user_id')
          result['user_id']
        else
          result['service_staff_id']
        end
        ww_id.gsub!('cntaobao','')
        ww_id = ww_id.split(':')
        {nick: (ww_id[1] || ww_id[0]), seller_nick: ww_id[0]}
      end
      
      def get_data(data)
        case
          when data.has_key?('reply_stat_list_on_days')
            data = data['reply_stat_list_on_days']['reply_stat_on_day']['reply_stat_by_ids']
            data['reply_stat_by_id'] unless data.nil?
          when data.has_key?('non_reply_stat_on_days')
            data = data['non_reply_stat_on_days']['non_reply_stat_on_day']['nonreply_stat_by_ids']
            data['nonreply_stat_by_id'] unless data.nil?
          when data.has_key?('waiting_time_list_on_days')
            data = data['waiting_time_list_on_days']['waiting_times_on_day']['waiting_time_by_ids']
            data['waiting_time_by_id'] unless data.nil?
          when data.has_key?('online_times_list_on_days')
            data = data['online_times_list_on_days']['online_times_on_day']['online_time_by_ids']
            data['online_time_by_id'] unless data.nil?
          when data.has_key?('staff_eval_stat_on_user')
            data['staff_eval_stat_on_user']
        end
      end
      
      def methods
        [
          # 'taobao.wangwang.eservice.receivenum.get', # 接待
          # 'taobao.wangwang.eservice.noreplynum.get', # 未回复
          # 'taobao.wangwang.eservice.avgwaittime.get', # 平均响应时间
          'taobao.wangwang.eservice.onlinetime.get', # 在线时长
        ]
      end
    end

  end
end