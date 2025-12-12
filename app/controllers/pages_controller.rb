class PagesController < ApplicationController
  def home
    @hot_posts = Post.includes(:user).order(likes_count: :desc).limit(5)
    @trending_tags = Tag.joins(:taggings).group('tags.id').order(Arel.sql('COUNT(taggings.id) DESC')).limit(6)
    @top_posts_by_tag = @trending_tags.index_with do |tag|
      tag.posts.includes(:user).order(likes_count: :desc).first
    end
    @news_top = Article.published.limit(1) rescue []
    @news_secondary = Article.published.offset(1).limit(4) rescue []
    @news_latest = Article.published.offset(5).limit(10) rescue []
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
