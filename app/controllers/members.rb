# -*- encoding: utf-8 -*-

One.controllers :members, :parent => :users do
  before do
    @page = 1 
    @page_size = 20
    @page = params[:page].to_i unless params[:page].blank?
    @page_size = params[:page_size].to_i unless params[:page_size].blank?
    @conditions = {seller_nick: user_id}
    # 时间区间
    unless ( params[:start_at].blank? && params[:end_at].blank? )
      @start_at = params[:start_at].to_date
      @end_at = params[:end_at].to_date
      @range = @start_at.beginning_of_day..@end_at.end_of_day
      @conditions.merge!(last_trade_time: @range)
    end
    unless params[:level].blank?
      @level = params[:level].to_i
      @conditions.merge!(grade: @level)
    end
    unless ( params[:min_amount].blank? && params[:max_amount].blank? )
      @min_amount = params[:min_amount].to_i
      @max_amount = params[:max_amount].to_i
      @conditions.merge!(trade_amount: @min_amount..@max_amount)
    end
    unless ( params[:min_count].blank? && params[:max_count].blank? )
      @min_count = params[:min_count].to_i
      @max_count = params[:max_count].to_i
      @conditions.merge!(trade_count: @min_count..@max_count)
    end
    unless params[:status].blank?
      @status = params[:status] if %w(normal delete blacklist).include?(params[:status])
      @conditions.merge!(status: @status)
    end
  end
  
  get :index, provides: [:html, :csv] do
    case content_type
      when :html
        @members = Member.where(@conditions).page(@page).per(@page_size)
        render 'members/index'
      when :csv
        @members = Member.where(@conditions)
        unless @members.empty?
          file_csv = export_members(@members, user_id)
          send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
        end
      end
  end
end