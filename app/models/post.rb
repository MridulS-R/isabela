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

  enum kind: { original: 0, repost: 1, quote: 2 }
  enum visibility: { public: 0, followers: 1, community: 2 }, _prefix: :visibility

  validates :caption, length: { maximum: 1000 }
  validate :content_presence
  validate :validate_topic_prefix_matches_community

  before_validation :extract_and_assign_topics
  after_commit :enqueue_auto_tag, on: :create
  after_commit :broadcast_to_community, on: :create
  after_commit -> { ModerationScoreJob.perform_later(kind: 'post', id: id) }, on: :create
  after_commit -> { RecomputeHotScoreJob.perform_later(id) }

  scope :recent, -> { order(created_at: :desc) }

  def content_presence
    # Reposts can be empty; originals/quotes must have either caption or images
    return if kind == 'repost'
    if caption.to_s.strip.empty? && !images.attached?
      errors.add(:base, 'Post must include text or an image')
    end
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

  def enqueue_auto_tag
    AutoTagPostJob.perform_later(id)
  end

  def broadcast_to_community
    return unless community_id.present?
    payload = {
      type: 'new_post',
      id: id,
      user_name: (user&.name.presence || user&.email),
      caption: caption.to_s,
      created_at: created_at.iso8601
    }
    ActionCable.server.broadcast("community:#{community_id}", payload)
  rescue => e
    Rails.logger.debug("community broadcast failed: #{e.class}: #{e.message}")
  end
end
