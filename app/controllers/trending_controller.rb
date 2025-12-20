class TrendingController < ApplicationController
  def index
    hours = (params[:hours] || 48).to_i.clamp(1, 240)
    since = hours.hours.ago
    @hours = hours

    @top_tags = Tag.joins(taggings: :post)
                   .where('posts.created_at >= ?', since)
                   .group('tags.id')
                   .order(Arel.sql('COUNT(taggings.id) DESC'))
                   .limit(20)
                   .select('tags.*, COUNT(taggings.id) as uses_count')

    @top_topics = Topic.joins(:posts)
                       .where('posts.created_at >= ?', since)
                       .group('topics.id')
                       .order(Arel.sql('COUNT(posts.id) DESC'))
                       .limit(20)
                       .select('topics.*, COUNT(posts.id) as posts_count')
  end

  def community
    @community = Community.find_by!(slug: params[:slug])
    hours = (params[:hours] || 48).to_i.clamp(1, 240)
    since = hours.hours.ago
    @hours = hours

    @top_tags = Tag.joins(taggings: :post)
                   .where('posts.created_at >= ? AND posts.community_id = ?', since, @community.id)
                   .group('tags.id')
                   .order(Arel.sql('COUNT(taggings.id) DESC'))
                   .limit(20)
                   .select('tags.*, COUNT(taggings.id) as uses_count')

    @top_topics = Topic.where(community_id: @community.id)
                       .joins(:posts)
                       .where('posts.created_at >= ?', since)
                       .group('topics.id')
                       .order(Arel.sql('COUNT(posts.id) DESC'))
                       .limit(20)
                       .select('topics.*, COUNT(posts.id) as posts_count')
  end
end

