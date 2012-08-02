# -*- encoding: utf-8 -*-

One.controllers :subusers, :parent => :users do
  
  before do
    default_at = Date.yesterday
    @start_at = params[:start_at] ? params[:start_at].to_date : default_at
    @end_at = params[:end_at] ? params[:end_at].to_date : default_at
    # 时间区间
    @range = @start_at.beginning_of_day..@end_at.end_of_day
  end
  
  get :index, :provides => [:html, :csv] do
    @subusers = Subuser.where(seller_nick: user_id).distinct('nick')
    unless @subusers.empty?
      @wangwangs = Wangwang.excludes(online_times: 0).where(date: @range, seller_nick: user_id).also_in(nick: @subusers)  # 月评价
      case content_type
        when :html
          render 'subusers/index'
        when :csv
          send_file export_wangwangs(@wangwangs, date_tag(@range), user_id)
      end
    else
      flash[:error] = '没有收到小弟。'
      redirect url(:users, :show, id:@user_id)
    end
  end
end