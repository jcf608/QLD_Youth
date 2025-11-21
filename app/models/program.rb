class Program < ActiveRecord::Base
  has_many :interventions
  has_many :youth_cases, through: :interventions
  has_many :youth, through: :youth_cases

  validates :name, :program_type, :status, presence: true
  validates :status, inclusion: { in: %w[active inactive] }
  validates :program_type, inclusion: { 
    in: %w[rehabilitation education employment counseling community_based residential]
  }

  scope :active, -> { where(status: 'active') }
end

