class FeedsController < ApplicationController
  before_action :require_admin!

  def index
    @feed = Feed.new
    @feeds = Feed.order(created_at: :desc)
  end

  def create
    @feed = Feed.new(feed_params)
    if @feed.save
      RefreshFeedJob.perform_later(@feed.id)
      redirect_to admin_feeds_path, notice: 'Feed added and refresh started.'
    else
      @feeds = Feed.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    feed = Feed.find(params[:id])
    feed.destroy
    redirect_to admin_feeds_path, notice: 'Feed removed.'
  end

  def refresh
    feed = Feed.find(params[:id])
    RefreshFeedJob.perform_later(feed.id)
    redirect_to admin_feeds_path, notice: 'Refresh queued.'
  end

  def refresh_all
    RefreshAllFeedsJob.perform_later
    redirect_to admin_feeds_path, notice: 'Refresh all queued.'
  end

  private
  def feed_params
    params.require(:feed).permit(:url, :active)
  end
end

