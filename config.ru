#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)
require 'new_relic/rack/developer_mode'
require 'resque_scheduler/server'
require 'faye'
require 'faye/redis'
require 'faye/auth'

use NewRelic::Rack::DeveloperMode
redis_uri = URI.parse(REDIS_URL)

run Rack::URLMap.new \
  '/'       => Padrino.application,
  '/resque' => Resque::Server.new,
  '/faye'   => Faye::RackAdapter.new(
    mount: '/pusher', 
    timeout: 25, 
    extensions: [Faye::Auth.new],
    engine: {
      type: Faye::Redis,
      host: redis_uri.host,
      password: redis_uri.password,
      port: redis_uri.port
  })

memory_usage = (`ps -o rss= -p #{$$}`.to_i / 1024.00).round(2)
puts "=> Memory usage: #{memory_usage} Mb"