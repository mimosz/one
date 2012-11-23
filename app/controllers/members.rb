# -*- encoding: utf-8 -*-

One.controllers :members, parent: :users do
  
  before do
    @page = 1 
    @page_size = 20
    @page = params[:page].to_i unless params[:page].blank?
    @page_size = params[:page_size].to_i unless params[:page_size].blank?
    @conditions = {seller_nick: user_id}
  end

  get :export, provides: [:html, :csv] do
    case content_type
    when :html
      render 'members/export'
    when :csv
      # 发货、创建
      field = 'pay_time' # 按支付（默认）
      unless params[:field].blank?
        if %w(consign_time created end_time modified).include?(params[:field])
          field = params[:field]
        end
      end
      # 时间区间
      start_at = Date.today
      end_at   = Date.today
      unless ( params[:start_at].blank? && params[:end_at].blank? )
        start_at = params[:start_at].to_date.beginning_of_day
        end_at   = params[:end_at].to_date.end_of_day
      end
      unless ( params[:start_time].blank? && params[:end_time].blank? )
        start_at = Time.parse( "#{params[:start_at]} #{params[:start_time]}"  )
        end_at   = Time.parse( "#{params[:end_at]} #{params[:end_time]}" )
      end
      range    = start_at..end_at
      buyer_nicks = Trade.where( @conditions.merge( field.to_sym => range) ).only(:buyer_nick).distinct(:buyer_nick)
      unless buyer_nicks.empty?
        members = Member.where( @conditions ).in( buyer_nick: buyer_nicks ).only(:buyer_id, :buyer_nick)
        unless members.empty?
          file_csv = user_id + '-' + field + '-' + start_at.in_time_zone.strftime("%Y-%m-%d") + '-' +  end_at.in_time_zone.strftime("%Y-%m-%d") + '会员信息.csv'
          header_row = ["会员ID", "昵称"]
          CSV.open(file_csv, "wb:GB18030", col_sep: ',') do |csv|
            csv << header_row
            members.each do |member|
              csv << [ member.buyer_id, member.buyer_nick ]
            end 
          end
          send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
        end
      end
    end
  end

  get :promotion do
    render 'members/new'
  end

  post :promotion do
    if params[:csv_file][:type] == 'text/csv'
      @member_ids = []
      @value = "sendShopBonus=1&amp;shopBonusDiscount=#{params[:discount]}&amp;shopBonusEndtime=#{params[:end_at]}"
      # 导入数据
      rows = CSV.read(params[:csv_file][:tempfile], 'rb:GB18030:UTF-8', headers: true, col_sep: ',')
      if rows.headers.include?('会员ID')
        rows.each do |row|
          @member_ids << row['会员ID'] if row['会员ID']
        end
      end
      if @member_ids.empty?
        flash[:error] = '模板错误，必须包含：会员ID。'
        redirect url(:members, :promotion, user_id: user_id)
      else
        # 匹配处理
        render 'members/promotion'
      end
    else
      flash[:error] = '必须是，Excel的CSV文本格式。'
      redirect url(:members, :promotion, user_id: user_id)
    end
  end

  get :index, provides: [:html, :csv] do
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
    case content_type
    when :html
      @members = Member.where(@conditions).page(@page).per(@page_size)
      render 'members/index'
    when :csv
      @members = Member.where(@conditions)
      if @members.empty?
          flash[:error] = '怎么可能，会员呢？'
          redirect url(:members, :index, user_id: user_id)
      else
        file_csv = export_members(@members, user_id)
        send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
      end
    end
  end

  get :show, with: :uid do
    @uid = params[:uid].force_encoding('utf-8').gsub('cntaobao','')

    @member = Member.where(@conditions.merge!(buyer_nick: @uid)).last
    if @member.nil?
      @trades = Trade.where( @conditions.merge( buyer_nick: @uid) ).desc(:created, :modified)
      @chatpeers = Chatpeer.where( @conditions.merge( uid: "cntaobao#{@uid}")  ).desc(:date)
    else
      @trades = @member.trades
      @chatpeers = @member.chatpeers
    end
    render 'members/show'
  end
end