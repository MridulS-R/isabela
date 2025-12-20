class PostsController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy like unlike comment repost quote pin unpin]
  before_action :set_post, only: %i[show like unlike repost quote edit update destroy pin unpin]
  before_action :require_owner!, only: %i[edit update destroy pin unpin]

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
    if !Services::RateLimiter.allow?("post:create:#{current_user.id}", limit: 10, period: 300)
      @post = current_user.posts.build
      @post.errors.add(:base, 'Rate limit exceeded. Please try again later.')
      return render :new, status: :too_many_requests
    end
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

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: 'Updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: 'Deleted.'
  end

  def like
    unless Services::RateLimiter.allow?("post:like:#{current_user.id}", limit: 60, period: 300)
      return redirect_back fallback_location: root_path, alert: 'Rate limit exceeded.'
    end
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
    unless Services::RateLimiter.allow?("post:comment:#{current_user.id}", limit: 30, period: 300)
      return redirect_back fallback_location: root_path, alert: 'Rate limit exceeded.'
    end
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

  def pin
    current_user.update!(pinned_post: @post)
    redirect_back fallback_location: post_path(@post), notice: 'Pinned to profile.'
  end

  def unpin
    if current_user.pinned_post_id == @post.id
      current_user.update!(pinned_post: nil)
    end
    redirect_back fallback_location: post_path(@post), notice: 'Unpinned.'
  end

  private
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:caption, :latitude, :longitude, :location, images: [])
  end

  def require_owner!
    redirect_to root_path, alert: 'Not authorized' unless @post.user_id == current_user.id
  end
end
