class Intervention < ActiveRecord::Base
  belongs_to :youth_case
  belongs_to :youth
  belongs_to :program, optional: true

  validates :youth_case_id, :youth_id, :intervention_type, :status, presence: true
  validates :status, inclusion: { in: %w[planned in_progress completed cancelled] }
  validates :intervention_type, inclusion: {
    in: %w[counseling education_support employment_training family_support substance_abuse mental_health community_service]
  }

  scope :active, -> { where(status: 'in_progress') }
  scope :by_type, ->(type) { where(intervention_type: type) }
end
