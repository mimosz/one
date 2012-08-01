#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)
require 'new_relic/rack/developer_mode'
require 'resque_scheduler/server'
use NewRelic::Rack::DeveloperMode

run Rack::URLMap.new \
  '/'       => Padrino.application,
  '/resque' => Resque::Server.new,
  '/redmon' => Redmon::App.new

memory_usage = (`ps -o rss= -p #{$$}`.to_i / 1024.00).round(2)
puts "=> Memory usage: #{memory_usage} Mb"