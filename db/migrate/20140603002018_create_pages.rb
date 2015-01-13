class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :url, limit: 1024, null: false
      t.string :image_url, limit: 1024
      t.string :title, limit: 1024
      t.string :site_name
      t.text :description
      t.text :html
      t.text :content
      t.text :content_html
      t.string :content_type
      t.text :fetch_error
      t.datetime :fetched_at
      t.integer :links_count, default: 0

      t.timestamps
    end
    add_index :pages, :url, unique: true
  end
end
