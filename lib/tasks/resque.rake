# -*- encoding: utf-8 -*-
require 'resque/tasks'
require 'resque_scheduler/tasks'

namespace :resque do
  
  desc "Launch single worker for processing jobs"
  task :worker => :environment do
    
    # - CONFIGURATION ----
    ENV['QUEUE']   ||= '*'
    ENV['COUNT']   ||= '10'
    ENV['VERBOSE']  = '1' # Verbose Logging
    # --------------------

    def queue
      ENV['QUEUE']
    end

    def count
      ENV['COUNT']
    end
    
    puts "=== Launching single worker on '#{ENV['QUEUE']}' queue(s) with PID #{Process.pid}"
    Rake::Task['resque:work'].invoke
  end
end
=begin

# 单任务
padrino rake resque:worker > tmp/logs/worker.log 2>&1 & \ 
padrino rake resque:scheduler > tmp/logs/scheduler.log 2>&1 & \
thin start

# 多任务
padrino rake workers:killall \
padrino rake workers:start > tmp/logs/workers.log 2>&1 & \
padrino rake resque:scheduler > tmp/logs/scheduler.log 2>&1 & \
thin start

=end