class PostsController < ApplicationController
  before_action :require_login, only: %i[new create like unlike comment]
  before_action :set_post, only: %i[show like unlike]

  def index
    @posts = Post.includes(:user, images_attachments: :blob)
    @posts = if params[:sort] == 'hot'
      @posts.order(likes_count: :desc)
    else
      @posts.recent
    end
    @posts = @posts.limit(50)
    @trending_tags = Tag.joins(:taggings).group('tags.id').order(Arel.sql('COUNT(taggings.id) DESC')).limit(10)
  end

  def show
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to root_path, notice: 'Posted!'
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
