# -*- encoding: utf-8 -*-

# 数据库
Resque.redis = REDIS_URL
# 加载计划的配置
Resque::Scheduler.dynamic = true
# Resque.schedule = YAML.load_file(Padrino.root('config/resque_schedule.yml'))
=begin
# 添加任务
User.each do |user|
  Resque.set_schedule("base-#{user.user_id}", { cron: '0 9 * * *', queue: :base, class: 'ResqueJobs::SyncUser', args: user.id })
  Resque.set_schedule("trades-#{user.user_id}", { every: '1h', queue: :trades, class: 'ResqueJobs::SyncTrade', args: user.id })
  Resque.set_schedule("items-#{user.user_id}", { every: '2h', queue: :items, class: 'ResqueJobs::SyncItem', args: user.id })
  Resque.set_schedule("shippings-#{user.user_id}-AM", { cron: '0 11 * * *', queue: :shippings, class: 'ResqueJobs::SyncShipping', args: user.id })
  Resque.set_schedule("shippings-#{user.user_id}-PM", { cron: '0 16 * * *', queue: :shippings, class: 'ResqueJobs::SyncShipping', args: user.id })
end
# 清除任务
User.each do |user|
  Resque.remove_schedule("base-#{user.user_id}")
  Resque.remove_schedule("trades-#{user.user_id}")
  Resque.remove_schedule("items-#{user.user_id}")
  Resque.remove_schedule("shippings-#{user.user_id}-AM")
  Resque.remove_schedule("shippings-#{user.user_id}-PM")
end
=end