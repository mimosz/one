source 'http://ruby.taobao.org/'

# Server requirements
gem 'unicorn'

group :production do
  gem 'padrino-csrf'
end

# Project requirements
gem 'rake'
gem 'sinatra-flash', require: 'sinatra/flash'
gem 'yajl-ruby', require: 'yajl'
gem 'nestful'
gem 'nokogiri'
gem 'topsdk', '~> 0.0.9'

# Component requirements
gem 'erubis', '~> 2.7.0'
gem 'mongoid', '~> 3.0.0'
gem 'kaminari', git: 'git://github.com/mimosa/kaminari.git', require: 'kaminari/sinatra'

# Jobs requirements
gem 'resque', require: 'resque/server'
gem 'resque-scheduler', '>= 2.0.0.e', require: 'resque_scheduler'
gem 'redis-objects', require: 'redis/objects'

# Test requirements
group :test do
  gem 'minitest', '~>2.6.0', require: 'minitest/autorun'
  gem 'rack-test', require: 'rack/test'
end

# Padrino Stable Gem
gem 'padrino', '0.10.7'
gem 'padrino-rpm'
gem 'grape'