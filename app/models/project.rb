require "csv"

class Project < ApplicationRecord
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  has_and_belongs_to_many :assigned_users, class_name: "User", join_table: "projects_users"
  has_many :bugs, dependent: :destroy

  has_one_attached :csv_file

  validates :name, presence: true, uniqueness: { message: "The name has aleady been set for another project" }
  validates :description, presence: true
  validates :manager_id, presence: true

  def self.to_csv
    attributes = %w[id name description manager, assigned_users created_at updated_at]

    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.find_each do |project|
        csv << [
        project.id,
        project.name,
        project.description,
        project.manager&.name,
        project.assigned_users.map(&:name).join(", "),
        project.created_at,
        project.updated_at
      ]
      end
    end
  end
end
