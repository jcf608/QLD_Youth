class CreateCaseNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :case_notes do |t|
      t.references :youth_case, null: false, foreign_key: true
      t.references :case_manager, null: false, foreign_key: true
      t.string :note_type, null: false, default: 'general'
      t.text :content, null: false
      t.boolean :is_confidential, default: false
      t.timestamps
    end

    add_index :case_notes, :note_type
    add_index :case_notes, :created_at
  end
end

