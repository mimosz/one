# -*- encoding: utf-8 -*-

One.controllers :resque, parent: :users do
  before do
    resque.reload_schedule! if resque::Scheduler.dynamic
    @user = User.find(user_id)
    @queues = {}
    @queues["base-#{@user.user_id}"]         = { cron: '0 9 * * *',  queue: :base,      class: 'ResqueJobs::SyncUser',     args: @user.id, description: '同步店铺：子账户、评价、仓储地址、旺旺聊天记录、客服绩效、会员' }
    @queues["trades-#{@user.user_id}"]       = { every: '1h',        queue: :trades,    class: 'ResqueJobs::SyncTrade',    args: @user.id, description: '同步店铺：交易、订单、退款' }
    @queues["items-#{@user.user_id}"]        = { every: '2h',        queue: :items,     class: 'ResqueJobs::SyncItem',     args: @user.id, description: '同步店铺：库存' }
    @queues["shippings-#{@user.user_id}-AM"] = { cron: '0 11 * * *', queue: :shippings, class: 'ResqueJobs::SyncShipping', args: @user.id, description: '同步店铺：物流运单' }
    @queues["shippings-#{@user.user_id}-PM"] = { cron: '0 16 * * *', queue: :shippings, class: 'ResqueJobs::SyncShipping', args: @user.id, description: '同步店铺：物流运单' }
  end

  get :index do
    render 'resque/index'
  end

  get :play, :with => :resque_id, provides: [:html, :js] do
    @resque_id = params[:resque_id].force_encoding('utf-8')
    @queue     = @queues[@resque_id]
    resque.set_schedule(@resque_id, @queue)
    if request.xhr?
      render 'resque/play', nil, layout: false
    else
      flash[:success] = '数据同步，已开始排期～'
      redirect url(:resque, :index, user_id: user_id)
    end
  end

  get :pause, :with => :resque_id, provides: [:html, :js] do
    @resque_id = params[:resque_id].force_encoding('utf-8')
    resque.remove_schedule(@resque_id)
    if request.xhr?
      @queue = @queues[@resque_id]
      render 'resque/pause', nil, layout: false
    else
      flash[:success] = '数据同步，已停止～'
      redirect url(:resque, :index, user_id: user_id)
    end
  end
end