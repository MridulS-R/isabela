class PostsController < ApplicationController
  before_action :require_login, only: %i[new create like unlike comment repost quote]
  before_action :set_post, only: %i[show like unlike repost quote]

  def index
    per = (params[:per] || 20).to_i.clamp(1, 100)
    page = (params[:page] || 1).to_i.clamp(1, 10_000)

    scope = Post.includes(:user, images_attachments: :blob)
    scope = params[:sort] == 'hot' ? scope.order(likes_count: :desc) : scope.recent

    @total_posts = Post.count
    @posts = scope.offset((page - 1) * per).limit(per)
    @page = page
    @per = per
    @has_more = (page * per) < @total_posts

    @communities = Community.order(followers_count: :desc).limit(20)
  end

  def show
    @post = Post.includes(:user, images_attachments: :blob).find(params[:id])
    unless can_view_post?(@post)
      return redirect_to(root_path, alert: 'Not authorized to view this post.')
    end
    @comments = @post.comments.includes(:user).order(created_at: :asc)
    @related_posts = if @post.respond_to?(:topics) && @post.topics.exists?
      Post.joins(:topics)
          .where(topics: { id: @post.topics.select(:id) })
          .where.not(id: @post.id)
          .distinct
          .order(likes_count: :desc, created_at: :desc)
          .limit(5)
    elsif @post.community_id.present?
      Post.where(community_id: @post.community_id)
          .where.not(id: @post.id)
          .order(likes_count: :desc, created_at: :desc)
          .limit(5)
    else
      Post.where.not(id: @post.id).order(likes_count: :desc).limit(5)
    end
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    slug = params.dig(:post, :community_slug).to_s.downcase.strip
    if slug.present?
      community = Community.find_by(slug: slug)
      unless community
        @post.errors.add(:base, "Community '#{slug}' not found")
        return render :new, status: :unprocessable_entity
      end
      @post.community = community
    end
    unless @post.community
      @post.errors.add(:base, 'Community is required')
      return render :new, status: :unprocessable_entity
    end
    if @post.save
      redirect_to posts_path, notice: 'Posted!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def like
    current_user.likes.find_or_create_by!(post: @post)
    if @post.user_id != current_user.id
      Notification.create!(user_id: @post.user_id, actor: current_user, action: 'like', notifiable: @post)
    end
    redirect_back fallback_location: root_path
  end

  def unlike
    current_user.likes.where(post_id: params[:id]).destroy_all
    redirect_back fallback_location: root_path
  end

  def comment
    post = Post.find(params[:id])
    post.comments.create!(user: current_user, body: params[:body].to_s)
    if post.user_id != current_user.id
      Notification.create!(user_id: post.user_id, actor: current_user, action: 'comment', notifiable: post)
    end
    redirect_back fallback_location: root_path
  end

  def repost
    original = @post
    rep = Post.new(user: current_user, community: original.community, parent_post: original, kind: :repost)
    if rep.save
      if original.user_id != current_user.id
        Notification.create!(user_id: original.user_id, actor: current_user, action: 'repost', notifiable: original)
      end
      redirect_back fallback_location: posts_path, notice: 'Reposted.'
    else
      redirect_back fallback_location: posts_path, alert: rep.errors.full_messages.to_sentence
    end
  end

  def quote
    original = @post
    body = params[:caption].to_s
    q = Post.new(user: current_user, community: original.community, parent_post: original, kind: :quote, caption: body)
    if q.save
      if original.user_id != current_user.id
        Notification.create!(user_id: original.user_id, actor: current_user, action: 'repost', notifiable: original)
      end
      redirect_back fallback_location: posts_path, notice: 'Quoted.'
    else
      redirect_back fallback_location: posts_path, alert: q.errors.full_messages.to_sentence
    end
  end

  private
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:caption, :latitude, :longitude, :location, images: [])
  end

  def can_view_post?(post)
    return true if post.visibility_public?
    return true if user_signed_in? && post.user_id == current_user.id
    if post.visibility_followers?
      return false unless user_signed_in?
      return current_user.following.exists?(id: post.user_id)
    end
    if post.visibility_community?
      return false unless user_signed_in? && post.community_id.present?
      return current_user.followed_communities.exists?(id: post.community_id)
    end
    false
  end
end
