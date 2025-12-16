class HomepageArticle < ApplicationRecord
  enum status: { draft: 0, scheduled: 1, published: 2, retired: 3 }
  enum slot: { lead: 1, secondary: 2, brief: 3 }

  belongs_to :community
  belongs_to :created_by, class_name: 'User', optional: true
  has_one_attached :md_file
  has_one_attached :hero_image

  validates :slot, presence: true
  validates :status, presence: true

  scope :visible, -> {
    where(status: :published)
      .where('published_at IS NULL OR published_at <= ?', Time.current)
      .where('unpublished_at IS NULL OR unpublished_at > ?', Time.current)
  }

  def metadata
    JSON.parse(metadata_json.to_s.presence || '{}') rescue {}
  end

  def metadata=(hash)
    self.metadata_json = hash.to_json
  end
end
