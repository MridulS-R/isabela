class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }

  def first_image_url
    return nil if body.blank?
    m = body.to_s.match(/<img[^>]+src=["']([^"']+)["']/i)
    m && m[1]
  end
end
