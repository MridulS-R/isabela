class Report < ApplicationRecord
  enum status: { open: 0, reviewing: 1, resolved: 2, rejected: 3 }
  belongs_to :user
  belongs_to :reportable, polymorphic: true

  validates :reason, presence: true
end

