class User < ApplicationRecord
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_secure_password
  has_one_attached :avatar

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[^\s@]+@[^\s@]+\z/ }
  validates :password, length: { minimum: 8 }, allow_nil: true
  before_validation :downcase_email

  private
  def downcase_email
    self.email = email.to_s.downcase
  end
end
