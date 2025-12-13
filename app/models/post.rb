class Post < ApplicationRecord
  HASHTAG_PATTERN = /#([a-z0-9]+)_([a-z0-9_]+)/

  belongs_to :user
  belongs_to :community, counter_cache: true, optional: true
  belongs_to :parent_post, class_name: 'Post', optional: true

  has_many_attached :images
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :post_topics, dependent: :destroy
  has_many :topics, through: :post_topics
  has_many :replies, class_name: 'Post', foreign_key: :parent_post_id

  validates :caption, length: { maximum: 1000 }
  validate :at_least_one_image
  validate :validate_topic_prefix_matches_community

  before_validation :extract_and_assign_topics

  scope :recent, -> { order(created_at: :desc) }

  def at_least_one_image
    errors.add(:images, 'must include at least one image') unless images.attached?
  end

  def extract_topic_pairs
    return [] if caption.blank?
    caption.downcase.scan(HASHTAG_PATTERN).uniq
  end

  private
  def extract_and_assign_topics
    return unless community
    pairs = extract_topic_pairs
    topics_list = []
    pairs.each do |(community_slug, topic_slug)|
      next unless community_slug == community.slug
      topic = Topic.find_or_create_by!(community_id: community.id, slug: topic_slug) do |t|
        t.name = topic_slug.humanize
      end
      topics_list << topic
    end
    self.topics = topics_list.uniq if topics_list.any?
  end

  def validate_topic_prefix_matches_community
    return unless community && caption.present?
    mismatches = extract_topic_pairs.reject { |c_slug, _| c_slug == community.slug }
    if mismatches.any?
      errors.add(:caption, "tags must start with ##{community.slug}_")
    end
  end
end
