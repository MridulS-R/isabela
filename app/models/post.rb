class Post < ApplicationRecord
  belongs_to :user
  has_many_attached :images
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :caption, length: { maximum: 1000 }
  validate :at_least_one_image

  before_save :extract_and_assign_tags

  scope :recent, -> { order(created_at: :desc) }

  def at_least_one_image
    errors.add(:images, 'must include at least one image') unless images.attached?
  end

  HASHTAG_REGEX = /#(\w+)/

  def extract_hashtags
    return [] if caption.blank?
    caption.scan(HASHTAG_REGEX).flatten.map { |t| t.downcase }.uniq
  end

  private
  def extract_and_assign_tags
    normalized = extract_hashtags
    self.tags = normalized.map { |name| Tag.find_or_create_by!(name: name) }
  end
end
