# -*- encoding: utf-8 -*-

One.controllers :accounts do

  get :index do
    @teaming  = current_account.teaming
    @accounts = current_account.teams
    render 'accounts/index'
  end

  get :new do
    render 'accounts/new', nil, layout: :session
  end

  post :create do
    @account = Account.new(params[:account])
    if @account.save
      flash[:notice] = '欢迎光临，.'
      redirect url(:accounts, :show, account_id: @account.id)
    else
      flash[:error] = '帐号信息错误。'
      render 'accounts/new', nil, layout: :session
    end
  end

  get :edit, :with => :account_id do
    @account = Account.find(params[:account_id])
    render 'accounts/edit'
  end
  
  get :show, :with => :account_id do
    @account = Account.find(params[:account_id])
    render 'accounts/show'
  end

  put :update, :with => :account_id do
    @account = Account.find(params[:account_id])
    if @account.update_attributes(params[:account])
      flash[:notice] = 'Account was successfully updated.'
      redirect url(:accounts, :show, account_id: @account.id)
    else
      render 'accounts/edit'
    end
  end

  delete :destroy, :with => :account_id do
    account = Account.find(params[:account_id])
    if account != current_account && account.destroy
      flash[:notice] = 'Account was successfully destroyed.'
    else
      flash[:error] = 'Unable to destroy Account!'
    end
    redirect url(:accounts, :index)
  end
end