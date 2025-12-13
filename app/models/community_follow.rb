class CommunityFollow < ApplicationRecord
  belongs_to :user
  belongs_to :community, counter_cache: :followers_count

  validates :user_id, uniqueness: { scope: :community_id }
end

