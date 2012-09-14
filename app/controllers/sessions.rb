# -*- encoding: utf-8 -*-

One.controllers :sessions do

  get :new do
    render "sessions/new", nil, layout: :session
  end

  post :create do
    if account = Account.authenticate(params[:email], params[:password])
      set_current_account(account)
      redirect url(:accounts, :show, account_id: account.id)
    else
      params[:email], params[:password] = h(params[:email]), h(params[:password])
      flash[:warning] = "不开～不开～就不开，妈妈没回来，谁叫也不开。"
      redirect url(:sessions, :new)
    end
  end

  delete :destroy do
    set_current_account(nil)
    redirect url(:sessions, :new)
  end
end