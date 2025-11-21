class CaseManager < ActiveRecord::Base
  has_many :cases, class_name: 'YouthCase', foreign_key: 'case_manager_id'
  has_many :youth, through: :cases

  validates :first_name, :last_name, :email, presence: true
  validates :email, uniqueness: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(options = {})
    super(options.merge(methods: [:full_name]))
  end
end

