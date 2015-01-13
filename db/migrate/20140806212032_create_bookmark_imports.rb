class CreateBookmarkImports < ActiveRecord::Migration
  def change
    create_table :bookmark_imports do |t|
      t.string :bookmark_file, null: false
      t.references :user, index: true
      t.integer :status, default: 0
      t.integer :bookmarks_count, default: 0

      t.timestamps
    end
  end
end
