class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?

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
end
