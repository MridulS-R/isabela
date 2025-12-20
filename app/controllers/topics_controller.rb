class TopicsController < ApplicationController
  def index
    @topics = Topic.joins(:posts)
                   .group('topics.id')
                   .order(Arel.sql('COUNT(posts.id) DESC'))
                   .limit(100)
                   .select('topics.*, COUNT(posts.id) as posts_count')
  end

  def community
    @community = Community.find_by!(slug: params[:slug])
    @topics = Topic.where(community_id: @community.id)
                   .joins(:posts)
                   .group('topics.id')
                   .order(Arel.sql('COUNT(posts.id) DESC'))
                   .limit(100)
                   .select('topics.*, COUNT(posts.id) as posts_count')
  end

  def show
    @community = Community.find_by!(slug: params[:slug])
    @topic = Topic.find_by!(community_id: @community.id, slug: params[:topic_slug])
    @posts = @topic.posts.includes(:user, images_attachments: :blob).order(created_at: :desc).limit(100)
  end
end

