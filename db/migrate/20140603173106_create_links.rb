class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.string :name, limit: 1024
      t.string :keywords, array: true, default: []
      t.text :note
      t.string :source, null: false
      t.string :source_id
      t.string :source_uid
      t.datetime :saved_at, null: false
      t.integer :saved_by, default: 0
      t.references :user, index: true, null: false
      t.references :page, index: true, null: false

      t.timestamps
    end
    add_index :links, :saved_by
    add_index :links, [:user_id, :page_id], unique: true
  end
end
