# -*- encoding: utf-8 -*-

One.controllers :refunds, :parent => :users do
  before do
    @field = 'modified' # 按修改时间
    @field = params[:field] if ['modified', 'created'].include?(params[:field])

    @start_at = params[:start_at] ? params[:start_at].to_date : Date.today
    @end_at = params[:end_at] ? params[:end_at].to_date : Date.today
    # 时间区间
    @range = @start_at.beginning_of_day..@end_at.end_of_day
  end

  get :index, :provides => [:html, :csv] do
    @refunds = Refund.where({seller_nick: user_id, @field.to_sym => @range}) # .also_in(status:['WAIT_SELLER_AGREE', 'WAIT_BUYER_RETURN_GOODS', 'WAIT_SELLER_CONFIRM_GOODS'])
    case content_type
      when :html
        render 'refunds/index'
      when :csv
        if @refunds.empty?
          flash[:error] = '非常庆幸，没有退款~'
          redirect url(:refunds, :index, user_id: user_id)
        else
          send_file export_refunds(@refunds, date_tag(@range), user_id) 
        end
    end 
  end
end