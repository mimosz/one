# -*- encoding: utf-8 -*-

One.controllers :trades, parent: :users do
  before do
    # 发货、创建
    @field = 'pay_time' # 按支付（默认）
    unless params[:field].blank?
      if %w(consign_time created end_time modified).include?(params[:field])
        @field = params[:field]
      end
    end
    # 时间区间
    @start_at = Date.today
    @end_at = Date.today
    unless ( params[:start_at].blank? && params[:end_at].blank? )
      @start_at = params[:start_at].to_date
      @end_at = params[:end_at].to_date
    end
    @range = @start_at.beginning_of_day..@end_at.end_of_day
    @trades = Trade.where(seller_nick: user_id, @field.to_sym => @range)
  end

  get :index, provides: [:html, :csv] do
    case content_type
      when :html
        @filter_list = FilterList.where(seller_nick: user_id, _id: '4f8120bf7d7baa025d000020')
        options = {
          item: true,
          sku: true,
          # status: true,
          # state: true,
          # timeline: { field: @field, unit: 'week'},
          # filter_list: @filter_list,
        }
        @trades = group_by(@trades, options)
        render 'trades/index'
      when :csv
        if @trades.empty?
          flash[:error] = '还没有交易呢，大伙加把劲吆～'
          redirect url(:trades, :index, user_id: user_id)
        else
          send_file export_trades(@trades, date_tag(@range), user_id) 
        end
    end 
  end
  
end