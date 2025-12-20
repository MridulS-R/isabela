class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?
  helper_method :admin_user?
  helper_method :unread_notifications_count
  helper_method :can_view_post?

  private
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
    if @current_user.blank?
      # Try remember me
      raw = cookies.signed[:remember_token]
      if raw.present?
        digest = Digest::SHA256.hexdigest(raw)
        @current_user = User.find_by(remember_token_digest: digest)
        session[:user_id] = @current_user.id if @current_user
      end
    end
    touch_user_session
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    return if user_signed_in?
    redirect_to login_path, alert: 'Please log in to continue.'
  end

  def touch_user_session
    return unless @current_user
    raw = cookies.signed[:session_token]
    return if raw.blank?
    digest = Digest::SHA256.hexdigest(raw)
    UserSession.where(user_id: @current_user.id, token_digest: digest).update_all(last_seen_at: Time.current)
  end

  def admin_user?
    return false unless user_signed_in?
    # Prefer role-based admin if available
    return true if current_user.respond_to?(:admin?) && current_user.admin?
    # Fallback to ENV-bound email check
    admin_email = ENV['ADMIN_EMAIL'].presence
    return current_user.email.to_s.downcase == admin_email.to_s.downcase if admin_email
    false
  end

  def require_admin!
    token = request.headers['X-Admin-Token'].presence || params[:token].presence
    allowed_by_token = token.present? && ENV['ADMIN_TOKEN'].present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV['ADMIN_TOKEN'])
    allowed_by_user = admin_user?
    return if allowed_by_token || allowed_by_user

    respond_to do |format|
      format.html { redirect_to login_path, alert: 'Not authorized' }
      format.json { render json: { error: 'unauthorized' }, status: :unauthorized }
    end
  end

  def unread_notifications_count
    return 0 unless user_signed_in?
    Notification.where(user_id: current_user.id, read_at: nil).count
  rescue
    0
  end

  def can_view_post?(post)
    return true if admin_user?
    return false if post.respond_to?(:hidden) && post.hidden? && !(user_signed_in? && post.user_id == current_user.id)
    return true if post.respond_to?(:visibility_public?) && post.visibility_public?
    return true if user_signed_in? && post.user_id == current_user.id
    if post.respond_to?(:visibility_followers?) && post.visibility_followers?
      return false unless user_signed_in?
      return current_user.following.exists?(id: post.user_id)
    end
    if post.respond_to?(:visibility_community?) && post.visibility_community?
      return false unless user_signed_in? && post.community_id.present?
      return current_user.followed_communities.exists?(id: post.community_id)
    end
    # Default deny if unknown
    false
  end
end
