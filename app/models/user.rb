class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  has_one_attached :profile_image
  before_save { self.email = email.downcase }

  has_many :bug_assignments, dependent: :destroy
  has_many :bugs, through: :bug_assignments

  has_many :managed_projects, class_name: "Project", foreign_key: "manager_id", dependent: :destroy
  has_and_belongs_to_many :projects

  has_many :comments, dependent: :destroy

  enum role: { developer: 0, tester: 1, manager: 2 }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :role, presence: true, inclusion: { in: roles.keys }
end
