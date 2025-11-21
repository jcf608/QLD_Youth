class CreateInterventions < ActiveRecord::Migration[7.0]
  def change
    create_table :interventions do |t|
      t.references :youth_case, null: false, foreign_key: true
      t.references :youth, null: false, foreign_key: true
      t.references :program, null: true, foreign_key: true
      t.string :intervention_type, null: false
      t.string :status, null: false, default: 'planned'
      t.text :description
      t.date :start_date
      t.date :end_date
      t.text :outcomes
      t.integer :attendance_rate
      t.timestamps
    end

    add_index :interventions, :status
    add_index :interventions, :intervention_type
  end
end

