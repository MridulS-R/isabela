class NewsCrawlController < ApplicationController
  before_action :require_login
  before_action :require_admin!

  protect_from_forgery with: :exception

  def enqueue
    CrawlNewsSourcesJob.perform_later
    redirect_to profile_path, notice: 'Crawl started.'
  end
end

