class CreateFolders < ActiveRecord::Migration
  def change
    create_table :folders do |t|
      t.string :name, null: false
      t.references :user, index: true, null: false
      t.integer :links_count, default: 0
      t.integer :parent_folder_id

      t.timestamps
    end

    add_index :folders, [:name, :user_id], unique: true
    add_index :folders, :parent_folder_id
  end
end
