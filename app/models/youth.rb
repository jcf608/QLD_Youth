class Youth < ActiveRecord::Base
  has_many :cases, class_name: 'YouthCase', foreign_key: 'youth_id'
  has_many :interventions, through: :cases
  has_many :case_managers, through: :cases

  validates :first_name, :last_name, :date_of_birth, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 10, less_than_or_equal_to: 17 }

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(options = {})
    super(options.merge(methods: [:full_name]))
  end
end

