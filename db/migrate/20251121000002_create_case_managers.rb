class CreateCaseManagers < ActiveRecord::Migration[7.0]
  def change
    create_table :case_managers do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :department
      t.text :specializations
      t.timestamps
    end

    add_index :case_managers, :email, unique: true
  end
end

