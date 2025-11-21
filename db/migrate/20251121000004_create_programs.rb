class CreatePrograms < ActiveRecord::Migration[7.0]
  def change
    create_table :programs do |t|
      t.string :name, null: false
      t.string :program_type, null: false
      t.text :description
      t.integer :duration_weeks
      t.integer :capacity
      t.string :location
      t.string :status, null: false, default: 'active'
      t.timestamps
    end

    add_index :programs, :status
    add_index :programs, :program_type
  end
end

