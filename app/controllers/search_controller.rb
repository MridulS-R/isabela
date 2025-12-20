class SearchController < ApplicationController
  def index
    @q = params[:q].to_s.strip
    @scope = (params[:scope].presence || 'posts')
    return if @q.blank?

    case @scope
    when 'users'
      @users = User.where('LOWER(name) LIKE ? OR LOWER(username) LIKE ?', like(@q), like(@q))
                   .order(created_at: :desc).limit(50)
    when 'tags'
      @tags = Tag.where('LOWER(name) LIKE ?', like(@q)).order(name: :asc).limit(50)
    else
      posts = Post.includes(:user, images_attachments: :blob)
                  .where('LOWER(caption) LIKE ?', like(@q))
                  .order(created_at: :desc).limit(100)
      @posts = posts.select { |p| can_view_post?(p) }.first(50)
    end
  end

  private
  def like(q)
    "%#{q.downcase}%"
  end
end

