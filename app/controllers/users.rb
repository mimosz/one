# -*- encoding: utf-8 -*-

One.controllers :users do

  get :auth, map: '/auth/:provider/callback' do
    auth    = request.env["omniauth.auth"]
    render 'users/auth'
  end

  get :index, map: '/' do
    @users = User.in(_id: current_account.user_ids)
    render 'users/index'
  end
  
  get :show, :with => :user_id do
    @user = User.find(user_id)
    @start_at = params[:start_at] ? params[:start_at].to_date : 7.days.ago.to_date
    @end_at = params[:end_at] ? params[:end_at].to_date : Date.today
    # 时间区间
    @range = @start_at.beginning_of_day..@end_at.end_of_day
    rates = @user.rates.where(date: @range)
    # 解析评价
    @rates = parse_rates(rates)
    @service = parse_rates(rates, 'service')
    @addresses = @user.addresses

    render 'users/show'
  end

  get :new do
    redirect Topsdk.authorize_url
  end

  get :create do
    unless current_account
      flash[:warning] = "狼，来啦～～"
      redirect url(:sessions, :new)
    end
    if params[:top_session]
      seller = User.get_user(params[:top_session]) 
      if seller
        user = User.where(_id: seller['nick']).last
         if user.nil?
          seller['account_id'] = current_account.id
          seller['session'] = params[:top_session]
          @user = User.create(seller)
          flash[:notice] = '恭喜你，生意兴隆～'
          redirect url(:users, :show, :user_id => @user.id)
         else
          flash[:notice] = '小二，有重复铺店的，要罚不？'
          redirect url(:users, :show, :user_id => user.id)
         end
      else
        flash[:warning] = "淘宝，又作恶啦～～请重新授权。"
        redirect url(:users, :new)
      end
    end
    redirect url(:users, :index)
  end
end