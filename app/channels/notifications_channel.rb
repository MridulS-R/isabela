class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user
    stream_from stream_name
  end

  private
  def stream_name
    "notifications:#{current_user.id}"
  end
end

