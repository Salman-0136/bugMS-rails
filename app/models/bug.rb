class Bug < ApplicationRecord
  has_many :bug_assignments, dependent: :destroy
  has_many :users, through: :bug_assignments

  has_many :comments, dependent: :destroy

  has_many_attached :files
  has_many_attached :images
  has_many_attached :videos

  enum priority: { low: 0, medium: 1, high: 2 }
  enum status: { open: 0, closed: 1, reopened: 2 }
  enum severity: { minor: 0, major: 1, critical: 2 }
  enum bug_type: { ui: 0, backend: 1, performance: 2, security: 3 }

  validates :title, presence: true
  validates :description, presence: true
  validates :bug_type, presence: true

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.priority ||= :low
    self.status ||= :open
    self.severity ||= :minor
  end

  def close!(completed_at = Time.current)
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
end
