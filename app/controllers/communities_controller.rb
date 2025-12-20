class CommunitiesController < ApplicationController
  before_action :set_community

  def show
    vis_public = Post.visibilities[:public]
    vis_followers = Post.visibilities[:followers]
    vis_community = Post.visibilities[:community]

    following_ids = user_signed_in? && current_user.respond_to?(:following) ? current_user.following.pluck(:id) : []
    member = user_signed_in? && current_user.respond_to?(:followed_communities) && current_user.followed_communities.exists?(id: @community.id)

    scope = Post.where(community_id: @community.id, hidden: false).includes(:user, images_attachments: :blob)
    scope = scope.where(
      [
        'posts.visibility = ? OR (posts.visibility = ? AND posts.user_id IN (?)) OR (posts.visibility = ? AND (? OR posts.user_id = ?))',
        vis_public,
        vis_followers, following_ids + (user_signed_in? ? [current_user.id] : []),
        vis_community, member, (user_signed_in? ? current_user.id : 0)
      ]
    )
    base = if ENV['FEED_RANKING'].to_s.downcase == 'on' || params[:sort] == 'ranked'
      scope.order(hot_score: :desc, created_at: :desc)
    else
      scope.order(created_at: :desc)
    end
    list = base.limit(50).to_a
    @promoted_ids = []
    begin
      promos = PromotedPost.active.order(Arel.sql('last_shown_at NULLS FIRST'), :impressions_count).limit(2)
      merged = []
      insert_every = 8
      pi = 0
      list.each_with_index do |p, idx|
        merged << p
        if ((idx + 1) % insert_every == 0) && promos[pi]
          merged << promos[pi].post
          @promoted_ids << promos[pi].post_id
          promos[pi].increment_impression! rescue nil
          pi += 1
        end
      end
      @posts = merged
    rescue
      @posts = list
    end
  end

  def news
    @articles = Article.where(community_id: @community.id).published.limit(40)
    @top_topics = Topic.where(community_id: @community.id).order(posts_count: :desc).limit(10) rescue []
  end

  private
  def set_community
    @community = Community.find_by!(slug: params[:slug])
  end
end
