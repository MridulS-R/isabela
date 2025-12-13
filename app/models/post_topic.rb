class PostTopic < ApplicationRecord
  belongs_to :post
  belongs_to :topic, counter_cache: :posts_count

  validates :post_id, uniqueness: { scope: :topic_id }
end

