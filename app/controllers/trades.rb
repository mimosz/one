# -*- encoding: utf-8 -*-

One.controllers :trades, parent: :users do
  before do
    @conditions = { seller_nick: user_id }
    
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

    @options = { item: true }
    unless params[:axis].blank?
      case params[:axis]
      when 'timeline'
        @unit = 'day'
        if %w(day week month year).include?(params[:unit])
          @unit = params[:unit]
        end
        @options.merge!(timeline: { field: @field, unit: @unit})
      when 'sku'
        @options.merge!(sku: true)
      when 'status'
        @options.merge!(status: true)
      when 'state'
        @options.merge!(state: true)
      end
      @axis = params[:axis]
    end
  end

  get :index, provides: [:html, :csv] do
    seller = User.find(user_id)
    ids = seller.employee_ids
    ids.delete(current_account.id) # 删除自己
    @employees = Account.find(ids)
    case content_type
      when :html
        @trades = group_by(@trades, @options)
        render 'trades/index'
      when :csv
        if @trades.empty?
          flash[:error] = '还没有交易呢，大伙加把劲吆～'
          redirect url(:trades, :index, user_id: user_id)
        else
          file_csv = export_trades(@trades, date_tag(@range), user_id)
          if params[:email]
            deliver(:notifier, :email_with_file, current_account, params[:email], file_csv) 
          end
          send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
        end
    end 
  end
  
end