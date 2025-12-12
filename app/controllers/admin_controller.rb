class AdminController < ApplicationController
  before_action :require_admin!

  def dashboard
    @counts = {
      users: User.count,
      posts: Post.count,
      likes: Like.count,
      comments: Comment.count,
      tags: Tag.count,
      follows: (defined?(Follow) ? Follow.count : 0)
    }

    # Posts per day (last 14 days)
    range = 13.days.ago.to_date..Date.today
    posts_by_day = Post.where(created_at: range.begin.beginning_of_day..range.end.end_of_day)
                       .group("DATE(created_at)")
                       .order("DATE(created_at)")
                       .count
    @series_posts_per_day = range.map { |d| [d, posts_by_day[d] || 0] }

    # Top entities
    @top_tags = Tag.joins(:taggings).group('tags.id').order(Arel.sql('COUNT(taggings.id) DESC')).limit(10)
    @top_users_by_posts = User.joins(:posts).group('users.id').order(Arel.sql('COUNT(posts.id) DESC')).limit(10)
    @top_posts = Post.order(likes_count: :desc, created_at: :desc).limit(10)
  end
end

