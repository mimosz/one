# -*- encoding: utf-8 -*-

One.mailer :notifier do
  defaults content_type: 'html'

  email :welcome_email do |account|
    subject '欢迎成为二货~'
    to account.email
    locals account: account
    provides :plain, :html
    render 'welcome_email'
  end

  email :email_with_file do |account, email, file|
    subject '附件投递'
    to email
    locals account: account
    provides :plain, :html
    render 'email_with_file'
    add_file filename: File.basename(file), content: File.open(file, 'rb') { |io| io.read }
  end
end