class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_secure_password
  has_one_attached :avatar

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[^\s@]+@[^\s@]+\z/ }
  validates :password, length: { minimum: 8 }, allow_nil: true
  before_validation :downcase_email

  private
  def downcase_email
    self.email = email.to_s.downcase
  end
end
