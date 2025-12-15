class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      unless user.confirmed?
        flash.now[:alert] = 'Please confirm your email before signing in.'
        return render :new, status: :unprocessable_entity
      end
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: 'Signed out.'
  end
end
