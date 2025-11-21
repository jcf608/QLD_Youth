class CreateYouthCases < ActiveRecord::Migration[7.0]
  def change
    create_table :youth_cases do |t|
      t.references :youth, null: false, foreign_key: true
      t.references :case_manager, null: false, foreign_key: true
      t.string :case_number
      t.string :case_type, null: false
      t.string :status, null: false, default: 'active'
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :court_reference
      t.text :conditions
      t.timestamps
    end

    add_index :youth_cases, :case_number, unique: true
    add_index :youth_cases, :status
    add_index :youth_cases, :case_type
  end
end

