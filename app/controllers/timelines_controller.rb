class TimelinesController < ApplicationController
  before_action :require_login

  def home
    per = (params[:per] || 20).to_i.clamp(1, 100)
    page = (params[:page] || 1).to_i.clamp(1, 10_000)

    user_ids = [current_user.id]
    if current_user.respond_to?(:following)
      user_ids += current_user.following.pluck(:id)
    end
    community_ids = []
    if current_user.respond_to?(:followed_communities)
      community_ids = current_user.followed_communities.pluck(:id)
    end

    scope = Post.includes(:user, images_attachments: :blob)
                .where('posts.user_id IN (?) OR posts.community_id IN (?)', user_ids.uniq, community_ids.uniq)
                .order(created_at: :desc)

    @total_posts = scope.count
    @posts = scope.offset((page - 1) * per).limit(per)
    @page = page
    @per = per
    @has_more = (page * per) < @total_posts
  end
end

