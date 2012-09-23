# -*- encoding: utf-8 -*-

One.controllers :employees do

  post :create do
    @employee = current_account.employees.new(params[:employee])
    if @employee.save
      flash[:notice] = "#{@employee.employee_name}：来啦，有事您吩咐~"
    else
      flash[:error] = "薪资没谈妥，#{@employee.employee_name} 不愿当伙计。"
    end
    redirect url(:accounts, :show, account_id: current_account)
  end

  delete :destroy, :with => :employee_id do
    employee_id = params[:employee_id].force_encoding('utf-8')
    employee = Employee.find(employee_id)
    labor = employee_id.split(':')
    if employee.destroy
      flash[:notice] = "#{labor[0]} 解除了，与 #{labor[1]} 的劳动关系，。"
    else
      flash[:error] = "#{labor[1]} 在 #{labor[0]} 的工作，交接不清。"
    end
    redirect url(:accounts, :show, account_id: current_account)
  end

end