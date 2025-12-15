class UserMailer < ApplicationMailer
  default from: ENV.fetch('MAIL_FROM', 'no-reply@example.com')

  def password_reset(user, raw_token)
    @user = user
    @url = url_for(controller: :passwords, action: :edit, id: user.id, token: raw_token, only_path: false)
    mail to: @user.email, subject: 'Reset your password'
  end

  def email_confirmation(user, raw_token)
    @user = user
    @url = url_for(controller: :confirmations, action: :show, id: user.id, token: raw_token, only_path: false)
    mail to: @user.email, subject: 'Confirm your email'
  end
end

