class TimelinesController < ApplicationController
  before_action :require_login

  def home
    per = (params[:per] || 20).to_i.clamp(1, 100)
    page = (params[:page] || 1).to_i.clamp(1, 10_000)

    following_ids = current_user.respond_to?(:following) ? current_user.following.pluck(:id) : []
    user_ids = ([current_user.id] + following_ids).uniq
    community_ids = current_user.respond_to?(:followed_communities) ? current_user.followed_communities.pluck(:id) : []

    base = Post.where(hidden: false).includes(:user, images_attachments: :blob)
               .where('posts.user_id IN (?) OR posts.community_id IN (?)', user_ids, community_ids)

    vis_public = Post.visibilities[:public]
    vis_followers = Post.visibilities[:followers]
    vis_community = Post.visibilities[:community]

    scope = base.where(
      [
        'posts.visibility = ? OR (posts.visibility = ? AND posts.user_id IN (?)) OR (posts.visibility = ? AND (posts.community_id IN (?) OR posts.user_id = ?))',
        vis_public,
        vis_followers, following_ids + [current_user.id],
        vis_community, community_ids, current_user.id
      ]
    )
    if ENV['FEED_RANKING'].to_s.downcase == 'on' || params[:sort] == 'ranked'
      scope = scope.order(hot_score: :desc, created_at: :desc)
    else
      scope = scope.order(created_at: :desc)
    end

    @total_posts = scope.count
    @posts = scope.offset((page - 1) * per).limit(per)
    @page = page
    @per = per
    @has_more = (page * per) < @total_posts
  end
end
