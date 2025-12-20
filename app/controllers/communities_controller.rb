class CommunitiesController < ApplicationController
  before_action :set_community

  def show
    @posts = Post.where(community_id: @community.id).includes(:user, images_attachments: :blob).recent.limit(50)
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
