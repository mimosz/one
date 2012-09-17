# Helper methods defined here can be accessed in any controller or view in the application

One.helpers do
  def account_can
    logged_in? && (current_account.role == 'admin' || @account == current_account.id)
  end
end
