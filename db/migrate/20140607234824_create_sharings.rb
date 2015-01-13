class CreateSharings < ActiveRecord::Migration
  def change
    create_table :sharings do |t|
      t.integer :creator_id, null: false
      t.references :folder, index: true, null: false
      t.references :user, index: true, null: false

      t.timestamps
    end
    add_index :sharings, :creator_id
    add_index :sharings, [:folder_id, :user_id], unique: true
  end
end
