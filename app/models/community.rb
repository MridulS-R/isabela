class Community < ApplicationRecord
  enum visibility: { public: 0, private: 1 }, _prefix: :visibility

  belongs_to :created_by, class_name: 'User'

  has_many :posts, dependent: :restrict_with_error
  has_many :topics, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :community_follows, dependent: :destroy
  has_many :followers, through: :community_follows, source: :user

  has_one_attached :avatar

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_\-]+\z/ }
end
