# -*- encoding: utf-8 -*-

# 应用模式
padrino_env   = ENV["PADRINO_ENV"] ||= ENV["RACK_ENV"] ||= 'development'
# 加载配置
resque_conf = YAML.load_file(Padrino.root('config/resque.yml'))[padrino_env]
# 数据库
Resque.redis = Redis.new(resque_conf)
# 加载计划的配置
Resque::Scheduler.dynamic = true
# Resque.schedule = YAML.load_file(Padrino.root('config/resque_schedule.yml'))
=begin
# 添加任务
User.all.each do |user|
  Resque.set_schedule("base-#{user.user_id}", { cron: '0 9 * * *', queue: :base, class: 'ResqueJobs::SyncUser', args: user.id })
  Resque.set_schedule("items-#{user.user_id}", { every: '2h', queue: :items, class: 'ResqueJobs::SyncItem', args: user.id })
  Resque.set_schedule("trades-#{user.user_id}", { every: '1h', queue: :trades, class: 'ResqueJobs::SyncTrade', args: user.id })
end
# 清除任务
User.all.each do |user|
  Resque.remove_schedule("base-#{user.user_id}")
  Resque.remove_schedule("items-#{user.user_id}")
  Resque.remove_schedule("trades-#{user.user_id}")
end
=end