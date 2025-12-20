class Notification < ApplicationRecord
  belongs_to :user          # recipient
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_commit :broadcast_count, on: :create

  private
  def broadcast_count
    count = Notification.where(user_id: user_id, read_at: nil).count
    ActionCable.server.broadcast("notifications:#{user_id}", { type: 'count', count: count })
  rescue => e
    Rails.logger.debug("notifications broadcast failed: #{e.class}: #{e.message}")
  end
end
