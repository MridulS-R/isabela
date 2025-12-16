class PagesController < ApplicationController
  def home
    # Prefer curated homepage articles; fallback to Articles
    # Prefer a published LEAD front-page article; otherwise fall back to most-recent visible of any slot
    lead_rec = (HomepageArticle.visible.lead.order(published_at: :desc).first rescue nil)
    lead_rec ||= (HomepageArticle.visible.order(published_at: :desc).first rescue nil)
    secondary_recs = HomepageArticle.visible.secondary.order(position: :asc, published_at: :desc).limit(4) rescue []
    brief_recs = HomepageArticle.visible.brief.order(position: :asc, published_at: :desc).limit(9) rescue []

    if lead_rec || secondary_recs.any? || brief_recs.any?
      @hp_lead = lead_rec
      @hp_secondary = secondary_recs
      @hp_briefs = brief_recs
    else
      @news_top = Article.published.limit(1) rescue []
      @news_secondary = Article.published.offset(1).limit(4) rescue []
      @news_latest = Article.published.offset(5).limit(10) rescue []
    end
  end

  def blog
    @current_source = params[:source].presence
    scope = Article.published
    scope = scope.where(source: @current_source) if @current_source
    @articles = scope
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
