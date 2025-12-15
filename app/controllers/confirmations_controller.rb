class ConfirmationsController < ApplicationController
  def show
    token = params[:token].to_s
    user = User.find_by(id: params[:id])
    unless user&.valid_token?('confirmation', token, expires_in: 7.days)
      return redirect_to login_path, alert: 'Confirmation link is invalid or expired.'
    end
    user.confirmed_at = Time.current
    user.clear_token!('confirmation')
    redirect_to login_path, notice: 'Your email has been confirmed. Please sign in.'
  end

  def resend
    if current_user&.confirmed?
      redirect_to profile_path, notice: 'Already confirmed.' and return
    end
    if current_user
      token = current_user.generate_token!('confirmation')
      UserMailer.email_confirmation(current_user, token).deliver_later rescue nil
      redirect_to profile_path, notice: 'Confirmation email sent.'
    else
      redirect_to login_path
    end
  end
end

