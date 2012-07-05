# -*- encoding: utf-8 -*-

module ResqueJobs
  
  class ResqueJob
  end
  
  class SyncUser < ResqueJob
    @queue = :base

    def self.perform(user_id)
      puts "=================开始同步#{user_id}店铺信息=================="
        User.find(user_id).subusers_sync # 店铺子账户
        User.find(user_id).rates_sync # 店铺评价
        User.find(user_id).addresses_sync # 仓储地址
        User.find(user_id).chatpeers_sync # 旺旺接待
        User.find(user_id).wangwangs_sync # 记录旺旺统计
        User.find(user_id).members_sync # 卖家的会员
      puts "=================结束同步#{user_id}店铺信息=================="
    end
  end

  class SyncTrade < ResqueJob 
    @queue = :trades
    
    def self.perform(user_id)
      puts "=================开始同步#{user_id}交易信息=================="
        User.find(user_id).trades_sync # 交易
        User.find(user_id).orders_sync # 订单
        User.find(user_id).refunds_sync # 退款
      puts "=================结束同步#{user_id}交易信息=================="
    end
  end
  
  class SyncItem < ResqueJob
    @queue = :items
      
    def self.perform(user_id)
      puts "=================开始同步#{user_id}货品信息=================="
        User.find(user_id).items_sync  # 货品
        User.find(user_id).skus_sync   # 单品
      puts "=================结束同步#{user_id}货品信息=================="
    end
  end
  
end