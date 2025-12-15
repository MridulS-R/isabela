class PasswordsController < ApplicationController
  def new
  end

  def create
    email = params[:email].to_s.downcase.strip
    user = User.find_by(email: email)
    # Always respond the same to avoid user enumeration
    if user
      token = user.generate_token!('reset_password')
      UserMailer.password_reset(user, token).deliver_later rescue nil
    end
    redirect_to login_path, notice: 'If your email exists with us, you will receive a reset link shortly.'
  end

  def edit
    @token = params[:token].to_s
    @user = User.find_by(id: params[:id])
    unless @user&.valid_token?('reset_password', @token, expires_in: 2.hours)
      redirect_to new_password_path, alert: 'Reset link is invalid or expired.'
    end
  end

  def update
    @token = params[:token].to_s
    @user = User.find_by(id: params[:id])
    unless @user&.valid_token?('reset_password', @token, expires_in: 2.hours)
      return redirect_to new_password_path, alert: 'Reset link is invalid or expired.'
    end
    if params[:password].to_s.length < 8
      flash.now[:alert] = 'Password must be at least 8 characters.'
      return render :edit, status: :unprocessable_entity
    end
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]
    if @user.save
      @user.clear_token!('reset_password')
      redirect_to login_path, notice: 'Password updated. You can sign in now.'
    else
      flash.now[:alert] = 'Please correct the errors below.'
      render :edit, status: :unprocessable_entity
    end
  end
end

