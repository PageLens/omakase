class CreateClicks < ActiveRecord::Migration
  def change
    create_table :clicks do |t|
      t.references :link, index: true, null: false
      t.references :user, index: true
      t.datetime :clicked_at, null: false

      t.timestamps
    end
  end
end
