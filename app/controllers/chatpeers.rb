# -*- encoding: utf-8 -*-

One.controllers :chatpeers, :parent => :users do
  before do
    @conditions = { seller_nick: user_id }

    # 时间区间
    unless params[:start_at].blank?
      @start_at = params[:start_at].to_date
      @range = @start_at
      unless params[:end_at].blank?
        @end_at = params[:end_at].to_date
        @range = @start_at..@end_at 
      end
      @conditions.merge!( date: @range)
    end
    
  end

  get :show, :with => :uid do
    @uid = params[:uid].force_encoding('utf-8').gsub('cntaobao','')
    @chatpeers = Chatpeer.where( @conditions ).any_of({uid: "cntaobao#{@uid}"}, {nick: @uid}).asc(:date)
    render 'chatpeers/index'
  end
end