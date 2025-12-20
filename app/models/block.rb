class Block < ApplicationRecord
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'
  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate :prevent_self_block

  private
  def prevent_self_block
    errors.add(:base, 'cannot block yourself') if blocker_id == blocked_id
  end
end

