class CrawlNewsSourcesJob < ApplicationJob
  queue_as :default

  def perform
    crawler = Services::NewsCrawler.new
    crawler.crawl_all
  end
end
