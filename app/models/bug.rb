class Bug < ApplicationRecord
  has_many :bug_assignments, dependent: :destroy
  has_many :users, through: :bug_assignments

  belongs_to :project

  has_many :comments, dependent: :destroy

  enum priority: { low: 0, medium: 1, high: 2 }
  enum status: { open: 0, closed: 1, reopened: 2 }
  enum severity: { minor: 0, major: 1, critical: 2 }
  enum bug_type: { ui: 0, backend: 1, performance: 2, security: 3 }

  validates :title, presence: true, length: { minimum: 6, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10 }
  validates :bug_type, presence: true, inclusion: { in: bug_types.keys }
  validates :users, presence: true

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.priority ||= :low
    self.status ||= :open
    self.severity ||= :minor
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
