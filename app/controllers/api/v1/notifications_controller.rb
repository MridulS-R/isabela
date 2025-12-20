module Api
  module V1
    class NotificationsController < Api::V1::BaseController
      def index
        ns = Notification.where(user_id: @current_user.id).recent.limit(100)
        render json: { notifications: ns.map { |n| serialize(n) } }
      end

      def read
        n = Notification.find_by(id: params[:id], user_id: @current_user.id)
        if n
          n.update(read_at: Time.current)
        end
        render json: { ok: true }
      end

      private
      def serialize(n)
        {
          id: n.id, action: n.action, actor_id: n.actor_id,
          notifiable_type: n.notifiable_type, notifiable_id: n.notifiable_id,
          read_at: n.read_at, created_at: n.created_at
        }
      end
    end
  end
end

