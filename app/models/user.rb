class User < ApplicationRecord
  has_secure_password

  has_many :bug_assignments, dependent: :destroy
  has_many :bugs, through: :bug_assignments

  has_many :comments, dependent: :destroy

  has_one_attached :profile_image

  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end
