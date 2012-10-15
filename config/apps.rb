# -*- encoding: utf-8 -*-

##
# Setup global project settings for your apps. These settings are inherited by every subapp. You can
# override these settings in the subapps as needed.
#
Padrino.configure_apps do
  enable :sessions
  enable  :authentication
  # enable  :store_location
  # disable :raise_errors
  # disable :show_exceptions
  set :session_secret, APP_TOKEN
  set :session_id, 'padrino_one'.to_sym
  set :login_page, '/sessions/new'

  set :delivery_method, smtp: { 
    address: 'smtp.exmail.qq.com',
    port: 25,
    user_name: 'noreply@innshine.com',
    password: 'feiming123',
    authentication: :plain,
    enable_starttls_auto: true  
  }
  set :mailer_defaults, from: '买它 <noreply@innshine.com>'
end

# Mounts the core application for this project
Padrino.mount('One').to('/')
# The line added to make Padrino add the Grape API as a subapp
Padrino.mount('API', app_class: 'APIS::API').to('/api')