class CreateYouth < ActiveRecord::Migration[7.0]
  def change
    create_table :youths do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.integer :age, null: false
      t.string :gender
      t.text :address
      t.string :phone
      t.string :emergency_contact
      t.string :emergency_phone
      t.timestamps
    end

    add_index :youths, [:first_name, :last_name]
  end
end

