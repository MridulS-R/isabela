class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: true
  validates :body, presence: true, length: { maximum: 1000 }

  after_commit -> { ModerationScoreJob.perform_later(kind: 'comment', id: id) }, on: :create
  after_commit -> { RecomputeHotScoreJob.perform_later(post_id) }
end
