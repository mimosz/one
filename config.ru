#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)
require 'new_relic/rack/developer_mode'
use NewRelic::Rack::DeveloperMode

run Rack::URLMap.new \
  '/'       => Padrino.application,
  '/resque' => Resque::Server.new,
  '/redmon' => Redmon::App.new