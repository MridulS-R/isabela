class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true
  validates :user_id, uniqueness: { scope: :post_id }
  after_commit -> { RecomputeHotScoreJob.perform_later(post_id) }
end
