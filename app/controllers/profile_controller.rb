class ProfileController < ApplicationController
  before_action :require_login

  def show
    @is_admin = admin_user?
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
