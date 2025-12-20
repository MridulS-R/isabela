class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = Notification.where(user_id: current_user.id).includes(:actor, :notifiable).recent.limit(100)
  end

  def read
    n = Notification.find_by(id: params[:id], user_id: current_user.id)
    if n
      n.update(read_at: Time.current)
      redirect_back fallback_location: notifications_path
    else
      redirect_to notifications_path
    end
  end
end

