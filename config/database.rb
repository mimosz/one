# -*- encoding: utf-8 -*-

host = 'mongoc2.grandcloud.cn'
port = 10005 || Mongo::Connection::DEFAULT_PORT 
username = 'howl'
password = 800622

database = case Padrino.env
  when :development then 'one_development'
  when :production  then 'one_production'
  when :test        then 'one_test'
end

Mongoid.configure do |config|
  config.use_utc = false
  config.skip_version_check = true
  config.persist_in_safe_mode = true
  db = Mongo::Connection.new(host, port, logger: Padrino.logger).db(database)
  db.authenticate(username, password) unless username.nil?
  config.master = db
end