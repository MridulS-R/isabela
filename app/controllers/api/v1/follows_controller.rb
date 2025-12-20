module Api
  module V1
    class FollowsController < Api::V1::BaseController
      def follow_user
        user = User.find(params[:id])
        return render json: { error: 'cannot follow yourself' }, status: :unprocessable_entity if user.id == @current_user.id
        @current_user.active_follows.find_or_create_by!(followed: user)
        render json: { ok: true }
      end

      def unfollow_user
        user = User.find(params[:id])
        @current_user.active_follows.where(followed_id: user.id).delete_all
        render json: { ok: true }
      end

      def follow_community
        c = Community.find_by!(slug: params[:slug])
        CommunityFollow.find_or_create_by!(user_id: @current_user.id, community_id: c.id)
        render json: { ok: true }
      end

      def unfollow_community
        c = Community.find_by!(slug: params[:slug])
        CommunityFollow.where(user_id: @current_user.id, community_id: c.id).delete_all
        render json: { ok: true }
      end
    end
  end
end

