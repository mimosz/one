# -*- encoding: utf-8 -*-

One.helpers do
  def account_can
    logged_in? && (current_account.role == 'admin' || @account._id == current_account._id)
  end

  def each_employees(employees)
    list = ''
    if employees.count > 0
      employees.each do |e|
        list << link_to(e[:name], url(:accounts, :show, account_id: e[:id]))
      end
    end
    list
  end
end
