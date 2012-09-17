# -*- encoding: utf-8 -*-

module Sync
  module Subuser
    extend ActiveSupport::Concern
    
    module ClassMethods
      def sync_create(session, seller_nick) # 旺旺子帐号
        options = { session: session, method: 'taobao.sellercenter.subusers.get', nick: seller_nick }
        subusers = Topsdk.get_with(options)
        if subusers.is_a?(Hash) && subusers.has_key?('subusers') # 用戶
          subusers = subusers['subusers']['sub_user_info']
          subusers.each do |subuser|
            current_subuser = where(_id: subuser['sub_id'].to_s).last # 已帳戶
            subuser['nick'].gsub!("#{seller_nick}:",'')
            if current_subuser.nil?
              create(subuser)
            else
              current_subuser.update_attributes!(subuser)
            end
          end
        else
          puts "================================请求"
          puts options
          puts "================================结果"
          puts subusers
        end
      end

    end # ClassMethods

  end # Subuser
end # Sync