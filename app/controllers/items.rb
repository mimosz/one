# -*- encoding: utf-8 -*-

One.controllers :items, :parent => :users do
  before do
    @page = 1 
    @page_size = 20
    @page = params[:page].to_i unless params[:page].blank?
    @page_size = params[:page_size].to_i unless params[:page_size].blank?
    @conditions = { nick: user_id }
    unless params[:outer_id].blank?
      @conditions.merge!( outer_id: /#{params[:outer_id]}/)
    end
  end

  get :new do
    render 'items/new'
  end

  post :skus do
    if params[:csv_file][:type] == 'text/csv'
      # 导入数据
      @skus = items_import(params[:csv_file][:tempfile])
      if @skus
        # 匹配处理
        @items = Item.where(nick: user_id, :_id.in => @skus.keys)
        render 'items/skus'
      else
        flash[:error] = '模板错误，必须包含：淘宝ID、SKU、颜色、尺码、库存。'
        redirect url(:items, :new, user_id: user_id)
      end
    else
      flash[:error] = '必须是，Excel的CSV文本格式。'
      redirect url(:items, :new, user_id: user_id)
    end
  end
  
  put :skus do
    @user = User.find(user_id)
    options = { # 基础参数
      session: @user.session, 
      method: 'taobao.item.sku.update',
    }
    items = params[:items]
    items.each do |num_iid, skus|
      options.merge!(num_iid: num_iid)
      skus.each do |sku|
          options['outer_id'] = sku['outer_id'] unless sku['outer_id'].blank?
          options['quantity'] = sku['quantity'] unless sku['quantity'].blank?
          puts Topsdk.get_with(options)
      end
    end
    flash[:notice] = '恭喜你，生意兴隆～'
    redirect url(:items, :index, user_id: user_id)
  end

  get :show, :with => :id do
    @item = Item.where(nick: user_id, id: params[:id]).last
    render 'items/show'
  end

  get :index, :provides => [:html, :csv] do

    case content_type
      when :html
        @items = Item.where(@conditions).desc(:duration).page(@page).per(@page_size)
        render 'items/index'
      when :csv
        @items = Item.where(@conditions)
        if @items.empty?
          flash[:error] = '怎么可能，货品呢？'
          redirect url(:items, :index, user_id: user_id)
        else
          file_csv = items_export(@items, ['sku'], user_id)
          send_file file_csv, type: 'text/csv', filename: File.basename(file_csv)
        end
        
    end
  end
end