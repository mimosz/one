# -*- encoding: utf-8 -*-
Grape::API.logger Padrino.logger

module APIS
  module Entities
    class SellerCredit < Grape::Entity
      expose :level, documentation: { desc: '信用等级', type: 'Integer' }
      expose :score, documentation: { desc: '信用总分', type: 'Integer' }
      expose :total_num, documentation: { desc: '评价总数', type: 'Integer' }
      expose :good_num, documentation: { desc: '好评总数', type: 'Integer' }
    end
    class Address < Grape::Entity
      expose :send_def, documentation: { desc: '是否默认发货地址', type: 'Boolean' }
      expose :get_def, documentation: { desc: '是否默认取货地址', type: 'Boolean' }
      expose :cancel_def, documentation: { desc: '是否默认退货地址', type: 'Boolean' }
    end
    class User < Grape::Entity
      expose :nick, documentation: { desc: '店铺名称', type: 'String' }
      expose :seller_credit, documentation: { desc: '卖家信用', type: 'Hash' , fields: APIS::Entities::SellerCredit.documentation }, using: APIS::Entities::SellerCredit
      expose :addresses, documentation: { desc: '地址', type: 'Array', fields: APIS::Entities::Address.documentation }, using: APIS::Entities::Address
    end
    class Order < Grape::Entity
      expose :outer_iid, documentation: { desc: '商家编码', type: 'String' }
      expose :outer_sku_id, documentation: { desc: '商家SKU', type: 'String' }
    end
    class Trade < Grape::Entity
      expose :num_iid, documentation: { desc: '宝贝ID', type: 'Integer' }
      expose :num, documentation: { desc: '购买数量', type: 'Integer' }
      expose :orders, documentation: { desc: '订单', type: 'Array', fields: APIS::Entities::Order.documentation }, using: APIS::Entities::Order
    end
  end
end