class PromotedPost < ApplicationRecord
  belongs_to :post
  scope :active, -> { where(active: true) }

  def increment_impression!
    update_columns(impressions_count: impressions_count + 1, last_shown_at: Time.current)
  end

  def increment_click!
    update_columns(clicks_count: clicks_count + 1)
  end
end

