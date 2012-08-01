# -*- encoding: utf-8 -*-
Grape::API.logger Padrino.logger

module APIS
  module Vendors
    module Global
    
      class API_v1 < Grape::API
        version 'v1', using: :header, vendor: 'global', format: :json
        
        rescue_from :all do |e|
          logger.error "API << #{env['REQUEST_METHOD']} #{env['PATH_INFO']}; errors: #{e.message}"
          rack_response({ error: e.class.name, message: e.message })
        end
        
        resource :users do
          desc "店铺列表", { 
            fields: APIS::Entities::User.documentation
          }
          get do
            @users = User.all
            present @users, with: APIS::Entities::User
          end

          desc "店铺交易数据。", { 
            fields: APIS::Entities::Trade.documentation, 
            params: {
              user_id: { desc: "店铺名称。", type: 'String', required: true },
              page: { desc: "当前页数。", type: 'Integer', required: false },
              per_page: { desc: "每页显示记录数。", type: 'Integer', required: false },
            }
          }
          get ':user_id/trades' do
            @trades = Trade.where( seller_nick: params[:user_id].force_encoding('utf-8') ).page( params[:page]||1 ).per( params[:per_page]||30 )
            present @trades, with: APIS::Entities::Trade
          end
        end
        
        desc "API接口说明。"
        get :doc do
          {
            versions: APIS::Vendors::Global::API_v1.versions,
            routes: APIS::Vendors::Global::API_v1.routes.map do |route|
              route_path = route.route_path.gsub('(.:format)', '').gsub(':version', route.route_version)
              {
                route: "#{route.route_method} #{route_path}",
                desc: "#{route.route_description}",
                params: route.route_params,
                fields: route.route_fields,
              }
            end
          }
        end
        
        desc "所有未知调用，皆被指向404错误。"
        get :any do
          logger.error "API << #{env['REQUEST_METHOD']} #{env['PATH_INFO']}; errors: Not Found"
          error!({message: "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}", errors: "Not Found"},404)
        end
        
      end
    end
  end
end