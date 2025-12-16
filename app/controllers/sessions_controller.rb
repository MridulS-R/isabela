class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      unless user.confirmed?
        admin_email = ENV['ADMIN_EMAIL'].to_s.downcase
        if (user.respond_to?(:admin?) && user.admin?) || (admin_email.present? && user.email.to_s.downcase == admin_email)
          # Auto-confirm trusted admin accounts on first login
          user.update_columns(confirmed_at: Time.current) rescue nil
        else
          flash.now[:alert] = 'Please confirm your email before signing in.'
          return render :new, status: :unprocessable_entity
        end
      end
      session[:user_id] = user.id
      # Create a session record and cookie for session management
      raw_session = SecureRandom.urlsafe_base64(24)
      UserSession.create!(user: user, token_digest: Digest::SHA256.hexdigest(raw_session), user_agent: request.user_agent.to_s.first(255), ip: request.remote_ip, last_seen_at: Time.current)
      cookies.signed[:session_token] = { value: raw_session, httponly: true, secure: Rails.env.production?, same_site: :lax }

      # Remember me
      if params[:remember_me].to_s == '1'
        raw = user.generate_token!('remember')
        user.update_columns(remember_created_at: Time.current) rescue nil
        cookies.permanent.signed[:remember_token] = { value: raw, httponly: true, secure: Rails.env.production?, same_site: :lax }
      else
        cookies.delete(:remember_token)
        user.clear_token!('remember') rescue nil
      end
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Delete only this session record
    raw = cookies.signed[:session_token]
    if raw.present? && current_user
      digest = Digest::SHA256.hexdigest(raw)
      UserSession.where(user_id: current_user.id, token_digest: digest).delete_all
    end
    cookies.delete(:session_token)
    cookies.delete(:remember_token)
    reset_session
    redirect_to root_path, notice: 'Signed out.'
  end
end
