module Api
  module V1
    class FeedsController < Api::V1::BaseController
      def home
        per = (params[:per] || 20).to_i.clamp(1, 100)
        following_ids = @current_user.following.pluck(:id) rescue []
        user_ids = ([@current_user.id] + following_ids).uniq
        community_ids = @current_user.followed_communities.pluck(:id) rescue []

        vis_public = Post.visibilities[:public]
        vis_followers = Post.visibilities[:followers]
        vis_community = Post.visibilities[:community]

        scope = Post.where(hidden: false)
                    .where('posts.user_id IN (?) OR posts.community_id IN (?)', user_ids, community_ids)
                    .where([
                      'posts.visibility = ? OR (posts.visibility = ? AND posts.user_id IN (?)) OR (posts.visibility = ? AND (posts.community_id IN (?) OR posts.user_id = ?))',
                      vis_public,
                      vis_followers, following_ids + [@current_user.id],
                      vis_community, community_ids, @current_user.id
                    ])
                    .order(created_at: :desc)

        posts = scope.limit(per).map { |p| serialize_post(p) }
        render json: { posts: posts }
      end

      private
      def serialize_post(p)
        {
          id: p.id,
          user: { id: p.user_id, name: p.user&.name, email: p.user&.email },
          community_id: p.community_id,
          caption: p.caption,
          likes_count: p.likes_count,
          comments_count: p.try(:comments_count) || 0,
          created_at: p.created_at.iso8601
        }
      end
    end
  end
end

