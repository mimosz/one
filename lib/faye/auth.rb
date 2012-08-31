# -*- encoding: utf-8 -*-

module Faye
  class Auth
    def incoming(message, callback)
      if message['channel'] !~ %r{^/meta/}
        if message['ext']['auth_token'] != APP_TOKEN
          message['error'] = '配对失败'
        end
      end
      callback.call(message)
    end
  end
end