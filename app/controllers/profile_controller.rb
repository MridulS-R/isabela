class ProfileController < ApplicationController
  before_action :require_login

  def show
    @is_admin = admin_user?
    @sessions = []
    if current_user
      @sessions = current_user.user_sessions.order(updated_at: :desc)
      @current_session_digest = Digest::SHA256.hexdigest(cookies.signed[:session_token].to_s) if cookies.signed[:session_token]
    end
  end

  def sign_out_others
    return redirect_to login_path unless current_user
    current = Digest::SHA256.hexdigest(cookies.signed[:session_token].to_s) if cookies.signed[:session_token]
    if current.present?
      current_user.user_sessions.where.not(token_digest: current).delete_all
      redirect_to profile_path, notice: 'Signed out of other sessions.'
    else
      redirect_to profile_path, alert: 'No active session token found.'
    end
  end

  def sign_out_all
    return redirect_to login_path unless current_user
    # Delete all session records for user
    current_user.user_sessions.delete_all
    # Clear remember token from DB and cookies
    current_user.update_columns(remember_token_digest: nil, remember_created_at: nil) rescue nil
    cookies.delete(:remember_token)
    # Clear current session cookie and reset
    cookies.delete(:session_token)
    reset_session
    redirect_to root_path, notice: 'Signed out from all devices.'
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attrs = profile_params
    # If password fields are blank, don't attempt to change password
    if attrs[:password].blank? && attrs[:password_confirmation].blank?
      attrs.except!(:password, :password_confirmation)
    end

    if @user.update(attrs)
      redirect_to profile_path, notice: 'Profile updated.'
    else
      flash.now[:alert] = 'Please correct the errors below.'
      render :edit, status: :unprocessable_entity
    end
  end

  private
  def profile_params
    params.require(:user).permit(:name, :username, :email, :bio, :avatar, :password, :password_confirmation)
  end
end
