class PostsController < ApplicationController
  before_action :require_login, only: %i[new create like unlike comment]
  before_action :set_post, only: %i[show like unlike]

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

    @trending_tags = Tag.joins(:taggings).group('tags.id').order(Arel.sql('COUNT(taggings.id) DESC')).limit(10)
  end

  def show
    @post = Post.includes(:user, images_attachments: :blob).find(params[:id])
    @comments = @post.comments.includes(:user).order(created_at: :asc)
    @more_from_user = @post.user.posts.where.not(id: @post.id).order(created_at: :desc).limit(5)
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to posts_path, notice: 'Posted!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def like
    current_user.likes.find_or_create_by!(post: @post)
    redirect_back fallback_location: root_path
  end

  def unlike
    current_user.likes.where(post_id: params[:id]).destroy_all
    redirect_back fallback_location: root_path
  end

  def comment
    post = Post.find(params[:id])
    post.comments.create!(user: current_user, body: params[:body].to_s)
    redirect_back fallback_location: root_path
  end

  private
  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:caption, images: [])
  end
end
