# -*- encoding: utf-8 -*-

One.controllers :filter_list, :parent => :users do
  before do
    @conditions = { seller_nick: user_id }
    @options = {}
  end

  get :index do
    filter_list = {}
    FilterList.where(@conditions).each do |filters|
      filter_list[filters.id.to_s] = filters
    end
    @filter_list = filter_list
    render 'filter_list/index'
  end
  
  get :show do
    # 时间区间
    @start_at = Date.today
    @end_at = Date.today
    unless ( params[:start_at].blank? && params[:end_at].blank? )
      @start_at = params[:start_at].to_date
      @end_at = params[:end_at].to_date
    end
    @range = @start_at.beginning_of_day..@end_at.end_of_day

    @trades = Trade.where( @conditions.merge( pay_time: @range ) )
    @list = []
    if params[:filter_list].blank?
      @filter_list = FilterList.where( @conditions.merge( parent_ids: [] ) )
    else
      @list = params[:filter_list]
      @filter_list = FilterList.where( @conditions.merge( :_id.in => @list ) )
    end
    
    @options.merge!( filter_list: @filter_list ) unless @filter_list.empty?
    @trades = group_by(@trades, @options)
    if @trades.has_key?(:unknown_ids)
      unless @trades[:unknown_ids].empty?
        @items = Item.any_in(num_iid: @trades[:unknown_ids]) 
        if @items.empty?
          session = User.find(user_id).session
          Item.sync_items(session, @trades[:unknown_ids])
          @items = Item.any_in(num_iid: @trades[:unknown_ids]) 
        end
      end
    end
    render 'filter_list/show'
  end
  
  get :new do
    @filter_list = FilterList.new
    render 'filter_list/new'
  end
  
  get :edit, :with => :id do
    @filter_list = FilterList.where(seller_nick: user_id, _id: params[:id]).last
    render 'filter_list/edit'
  end
  
  post :create do
    params[:filter_list]['outer_ids'] = params[:filter_list]['outer_ids'].split("\r\n")
    @filter_list = FilterList.new(params[:filter_list])
    @filter_list[:seller_nick] = user_id
    if @filter_list.save
      flash[:notice] = '请核实，滤器信息～'
      redirect url(:filter_list, :edit, user_id: user_id, id: @filter_list.id )
    else
      render 'filter_list/new'
    end
  end
  
  put :update, :with => :id do
    @filter_list = FilterList.where(seller_nick: user_id, _id: params[:id]).last
    params[:filter_list]['outer_ids'] = params[:filter_list]['outer_ids'].split("\r\n")
    params[:filter_list]['child_ids'] ||= []
    current_child_ids = @filter_list.child_ids
    if @filter_list.update_attributes(params[:filter_list])
      remove = current_child_ids - @filter_list.child_ids
      @filter_list.cache_parents(remove, :remove) if remove.count > 0
      add = @filter_list.child_ids - current_child_ids
      @filter_list.cache_parents(add, :add) if add.count > 0
      flash[:notice] = '过滤器，准备就绪～'
      redirect url(:filter_list, :index, user_id: user_id)
    else
      render 'filter_list/edit'
    end
  end
end