class CaseNote < ActiveRecord::Base
  belongs_to :youth_case
  belongs_to :case_manager

  validates :youth_case_id, :case_manager_id, :content, presence: true
  validates :note_type, inclusion: { in: %w[general incident progress review court] }

  default_scope { order(created_at: :desc) }

  def created_at_formatted
    created_at.strftime('%B %d, %Y at %I:%M %p')
  end

  def as_json(options = {})
    super(options.merge(methods: [:created_at_formatted]))
  end
end

