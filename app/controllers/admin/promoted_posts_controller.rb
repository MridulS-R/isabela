class Admin::PromotedPostsController < ApplicationController
  before_action :require_login
  before_action :require_admin!
  before_action :set_record, only: [:destroy, :activate, :deactivate]

  def index
    @records = PromotedPost.includes(:post).order(updated_at: :desc)
  end

  def create
    post = Post.find_by(id: params[:post_id])
    return redirect_back fallback_location: admin_promoted_posts_path, alert: 'Post not found.' unless post
    PromotedPost.create!(post: post, weight: params[:weight].to_i.clamp(1, 10))
    redirect_to admin_promoted_posts_path, notice: 'Promoted placement created.'
  end

  def destroy
    @record.destroy
    redirect_to admin_promoted_posts_path, notice: 'Removed.'
  end

  def activate
    @record.update!(active: true)
    redirect_to admin_promoted_posts_path, notice: 'Activated.'
  end

  def deactivate
    @record.update!(active: false)
    redirect_to admin_promoted_posts_path, notice: 'Deactivated.'
  end

  private
  def set_record
    @record = PromotedPost.find(params[:id])
  end
end

