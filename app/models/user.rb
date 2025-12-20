class User < ApplicationRecord
  enum role: { member: 0, admin: 1 }
  has_many :community_follows, dependent: :destroy
  has_many :followed_communities, through: :community_follows, source: :community
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :post
  belongs_to :pinned_post, class_name: 'Post', optional: true
  has_many :blocks_initiated, class_name: 'Block', foreign_key: 'blocker_id', dependent: :destroy
  has_many :blocked_users, through: :blocks_initiated, source: :blocked
  has_many :blocks_received, class_name: 'Block', foreign_key: 'blocked_id', dependent: :destroy
  has_many :blocked_by_users, through: :blocks_received, source: :blocker
  has_secure_password
  has_one_attached :avatar

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[^\s@]+@[^\s@]+\z/ }
  validates :password, length: { minimum: 8 }, allow_nil: true
  before_validation :downcase_email

  private
  def downcase_email
    self.email = email.to_s.downcase
  end

  # Token helpers (confirmation / password reset)
  public
  def blocked?(other_user_id)
    blocked_users.exists?(id: other_user_id)
  end
  def generate_token!(field_prefix)
    raw = SecureRandom.urlsafe_base64(24)
    digest = Digest::SHA256.hexdigest(raw)
    self["#{field_prefix}_token_digest"] = digest
    self["#{field_prefix}_sent_at"] = Time.current if has_attribute?("#{field_prefix}_sent_at")
    save!(validate: false)
    raw
  end

  def clear_token!(field_prefix)
    self["#{field_prefix}_token_digest"] = nil
    self["#{field_prefix}_sent_at"] = nil if has_attribute?("#{field_prefix}_sent_at")
    save!(validate: false)
  end

  def valid_token?(field_prefix, raw, expires_in: 1.hour)
    return false if raw.to_s.blank?
    digest = self["#{field_prefix}_token_digest"]
    return false if digest.blank?
    return false if has_attribute?("#{field_prefix}_sent_at") && self["#{field_prefix}_sent_at"].present? && self["#{field_prefix}_sent_at"] < expires_in.ago
    ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(raw), digest)
  end

  def confirmed?
    confirmed_at.present?
  end
end
