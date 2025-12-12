class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?
  helper_method :admin_user?

  private
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    return if user_signed_in?
    redirect_to login_path, alert: 'Please log in to continue.'
  end

  def admin_user?
    return false unless user_signed_in?
    admin_email = ENV['ADMIN_EMAIL']
    return true if admin_email.blank?
    current_user.email.to_s.downcase == admin_email.to_s.downcase
  end
end
