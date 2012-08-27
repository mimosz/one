# -*- encoding: utf-8 -*-

One.controllers :trades, parent: :users do
  before do
    @conditions = { seller_nick: user_id }
    @options = { item: true }
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
    @trades = Trade.where( @conditions.merge( @field.to_sym => @range) )
    unless params[:timeline].blank?
      @timeline = { field: @field, unit: 'week'}
      @options.merge!(timeline: @timeline)
    end
    unless params[:sku].blank?
      @sku = true
      @options.merge!(sku: @sku)
    end
    unless params[:status].blank?
      @status = true
      @options.merge!(status: @status)
    end
    unless params[:state].blank?
      @state = true
      @options.merge!(state: @state)
    end
  end

  get :index, provides: [:html, :csv] do
    case content_type
      when :html
        # item: true,
        # sku: true,
        # status: true,
        # state: true,
        # timeline: { field: @field, unit: 'week'},
        # filter_list: @filter_list,
        @trades = group_by(@trades, @options)
        render 'trades/index'
      when :csv
        if @trades.empty?
          flash[:error] = '还没有交易呢，大伙加把劲吆～'
          redirect url(:trades, :index, user_id: user_id)
        else
          file_csv = export_trades(@trades, date_tag(@range), user_id)
          # export_rayban_trades(@trades, date_tag(@range), 'rayban')
          send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
        end
    end 
  end
  
end