class BookmarksController < ApplicationController
  before_action :require_login

  def index
    @posts = current_user.bookmarked_posts.includes(:user, images_attachments: :blob).order('bookmarks.created_at DESC')
  end

  def create
    post = Post.find(params[:id])
    Bookmark.find_or_create_by!(user_id: current_user.id, post_id: post.id)
    redirect_back fallback_location: bookmarks_path, notice: 'Saved.'
  end

  def destroy
    post = Post.find(params[:id])
    Bookmark.where(user_id: current_user.id, post_id: post.id).delete_all
    redirect_back fallback_location: bookmarks_path, notice: 'Removed.'
  end
end

