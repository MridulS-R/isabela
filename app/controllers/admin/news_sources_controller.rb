class Admin::NewsSourcesController < ApplicationController
  before_action :require_login
  before_action :require_admin!
  before_action :set_source, only: [:edit, :update, :destroy, :crawl]

  def index
    @sources = NewsSource.includes(:community).order(updated_at: :desc)
    @source = NewsSource.new
  end

  def create
    @source = NewsSource.new(source_params)
    if @source.save
      redirect_to admin_news_sources_path, notice: 'Source added.'
    else
      @sources = NewsSource.order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @source.update(source_params)
      redirect_to admin_news_sources_path, notice: 'Source updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to admin_news_sources_path, notice: 'Source removed.'
  end

  def crawl
    NewsCrawler.new.crawl_source_record(@source)
    redirect_to admin_news_sources_path, notice: 'Crawl completed for this source.'
  end

  private
  def set_source
    @source = NewsSource.find(params[:id])
  end

  def source_params
    p = params.require(:news_source).permit(:name, :community_id, :kind, :link_selector, :body_selector, :date_selector, :active, :list_urls)
    # allow list_urls as newline-separated textarea
    if p[:list_urls].present? && p[:list_urls].is_a?(String)
      urls = p[:list_urls].to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
      p[:list_urls] = urls.to_json
    end
    p
  end
end

