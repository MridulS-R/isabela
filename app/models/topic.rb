class Topic < ApplicationRecord
  belongs_to :community
  has_many :post_topics, dependent: :destroy
  has_many :posts, through: :post_topics

  validates :slug, presence: true
  validates :name, presence: true
  validates :slug, uniqueness: { scope: :community_id }
end

