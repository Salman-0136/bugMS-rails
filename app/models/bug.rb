require "csv"

class Bug < ApplicationRecord
  has_many :bug_assignments, dependent: :destroy
  has_many :users, through: :bug_assignments

  has_one_attached :csv_file

  belongs_to :project

  has_many :comments, dependent: :destroy

  enum priority: { low: 0, medium: 1, high: 2 }
  enum status: { open: 0, closed: 1, reopened: 2 }
  enum severity: { minor: 0, major: 1, critical: 2 }
  enum bug_type: { ui: 0, backend: 1, performance: 2, security: 3 }

  validates :title, presence: true, length: { minimum: 6, maximum: 100 }, uniqueness: { message: "The title has already been set for another bug" }
  validates :description, presence: true, length: { minimum: 10 }
  validates :bug_type, presence: true, inclusion: { in: bug_types.keys }

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.priority ||= :low
    self.status ||= :open
    self.severity ||= :minor
  end

  def self.to_csv
    attributes = %w[id title description due_date time_lapse priority severity status bug_type project manager project_assignees bug_assignees created_at updated_at]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      Bug.includes(
        :users,
        project: [ :manager, :assigned_users ]
      ).find_each(batch_size: 1000) do |bug|
        csv << [
          bug.id,
          bug.title,
          bug.description,
          bug.due_date,
          bug.time_lapse,
          bug.priority,
          bug.severity,
          bug.status,
          bug.bug_type,
          bug.project&.name,
          bug.project&.manager&.name,
          bug.project&.assigned_users&.map(&:name).join(", "),
          bug.users.map(&:name).join(", "),
          bug.created_at,
          bug.updated_at
        ]
      end
    end
  end

  def close!(completed_at = Time.current)
    completed_at = completed_at.to_time if completed_at.is_a?(String)
    self.time_lapse = ((completed_at - created_at) / 60).to_i
    self.status = :closed
    save
  end

  def reopen!
    if closed?
      self.status = :reopened
      save
    else
      errors.add(:status, "Only closed bugs can be reopened")
      false
    end
  end

  def formatted_time_lapse
    return nil unless time_lapse

    total_seconds = (time_lapse * 60).to_i

    days  = total_seconds / (24 * 3600)
    hours = (total_seconds % (24 * 3600)) / 3600
    mins  = (total_seconds % 3600) / 60
    secs  = total_seconds % 60

    result = []
    result << "#{days}d" if days > 0
    result << "#{hours}h" if hours > 0
    result << "#{mins}m" if mins > 0
    result << "#{secs}s" if secs > 0

    result.join(" ")
  end
end
