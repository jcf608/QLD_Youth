class YouthCase < ActiveRecord::Base
  belongs_to :youth
  belongs_to :case_manager
  has_many :interventions
  has_many :case_notes
  has_many :programs, through: :interventions

  validates :youth_id, :case_manager_id, :case_type, :status, presence: true
  validates :status, inclusion: { in: %w[active closed pending review] }
  validates :case_type, inclusion: { in: %w[detention community_order diversion rehabilitation] }

  scope :active, -> { where(status: 'active') }
  scope :by_case_manager, ->(manager_id) { where(case_manager_id: manager_id) }
end

