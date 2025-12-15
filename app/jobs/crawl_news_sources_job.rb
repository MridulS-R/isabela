class CrawlNewsSourcesJob < ApplicationJob
  queue_as :default

  def perform
    crawler = NewsCrawler.new
    crawler.crawl_all
  end
end

