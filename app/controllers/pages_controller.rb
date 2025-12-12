class PagesController < ApplicationController
  def home
    @hot_posts = Post.includes(:user).order(likes_count: :desc).limit(5)
    @trending_tags = Tag.joins(:taggings).group('tags.id').order(Arel.sql('COUNT(taggings.id) DESC')).limit(6)
    @top_posts_by_tag = @trending_tags.index_with do |tag|
      tag.posts.includes(:user).order(likes_count: :desc).first
    end
    @latest_articles = Article.published.limit(3) rescue []
  end
  def solutions; end
  def data_coverage; end
  def how_it_works; end
  def about; end
  def blog
    @articles = Article.published
  end
  def contact; end
end
