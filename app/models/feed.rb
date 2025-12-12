class Feed < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  scope :active, -> { where(active: true) }
end

