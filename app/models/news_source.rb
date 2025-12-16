class NewsSource < ApplicationRecord
  enum kind: { rss: 0, website: 1, sitemap: 2 }
  belongs_to :community

  validates :name, presence: true
  validates :kind, presence: true
  validates :list_urls, presence: true, if: -> { !rss? }

  def urls
    Array(JSON.parse(list_urls.to_s)) rescue Array(list_urls)
  end

  def urls=(arr)
    self.list_urls = Array(arr).to_json
  end
end

