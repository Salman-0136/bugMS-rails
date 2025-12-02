class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :bug

  has_many_attached :attachments

  validates :content, presence: true
end
