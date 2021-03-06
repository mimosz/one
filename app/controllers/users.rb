# -*- encoding: utf-8 -*-

One.controllers :users do

  get :auth, map: '/auth/:provider/callback' do
    @code = params[:code]
    render 'users/auth'
  end

  get :index do
    @users   = User.in(_id: current_account.seller_ids)
    @sysinfo = get_sysinfo
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
      seller = User.get_seller(params[:top_session]) 
      if seller
        user = User.where(_id: seller['nick']).last
         if user.nil?
          user = current_account.sellers.create(seller)
          flash[:notice] = '恭喜你，生意兴隆～'
         else
          flash[:warning] = '小二，有重复铺店的，要罚不？'
         end
         redirect url(:users, :show, user_id: user.id)
      else
        flash[:warning] = "淘宝，又作恶啦～～请重新授权。"
        redirect url(:users, :new)
      end
    end
    redirect url(:users, :index)
  end
end