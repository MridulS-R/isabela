class Admin::HomepageArticlesController < ApplicationController
  before_action :require_login
  before_action :require_admin!
  before_action :set_record, only: [:edit, :update, :destroy, :publish, :retire]

  def index
    @records = HomepageArticle.includes(:community).order(updated_at: :desc)
    @record = HomepageArticle.new
  end

  def create
    @record = HomepageArticle.new(record_params)
    @record.created_by = current_user
    # Allow using a default 'general' community if requested
    if @record.community_id.blank? && params[:use_default].to_s == '1'
      general = Community.find_or_create_by!(slug: 'general') do |c|
        c.name = 'General'
        c.created_by = current_user
        c.visibility = :publicly_visible
      end
      @record.community = general
    end
    if params[:homepage_article][:md_file]
      @record.md_file.attach(params[:homepage_article][:md_file])
    end
    if @record.save
      ParseHomepageArticleJob.perform_later(@record.id) if @record.md_file.attached?
      redirect_to admin_homepage_articles_path, notice: 'Front page article created.'
    else
      @records = HomepageArticle.order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if params[:homepage_article][:md_file]
      @record.md_file.attach(params[:homepage_article][:md_file])
    end
    attrs = record_params
    if attrs[:community_id].blank? && params[:use_default].to_s == '1'
      general = Community.find_or_create_by!(slug: 'general') do |c|
        c.name = 'General'
        c.created_by = current_user
        c.visibility = :publicly_visible
      end
      attrs = attrs.merge(community_id: general.id)
    end
    if @record.update(attrs)
      ParseHomepageArticleJob.perform_later(@record.id) if @record.md_file.attached?
      redirect_to admin_homepage_articles_path, notice: 'Updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @record.update!(status: :published, published_at: Time.current)
    redirect_to admin_homepage_articles_path, notice: 'Published.'
  end

  def retire
    @record.update!(status: :retired, unpublished_at: Time.current)
    redirect_to admin_homepage_articles_path, notice: 'Retired.'
  end

  def destroy
    @record.destroy
    redirect_to admin_homepage_articles_path, notice: 'Removed.'
  end

  private
  def set_record
    @record = HomepageArticle.find(params[:id])
  end

  def record_params
    params.require(:homepage_article).permit(:community_id, :slot, :position, :status, :published_at, :unpublished_at)
  end
end
