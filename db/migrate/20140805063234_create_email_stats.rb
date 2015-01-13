class CreateEmailStats < ActiveRecord::Migration
  def change
    create_table :email_stats do |t|
      t.string :email, :null => false
      t.string :tag
      t.string :status

      t.timestamps
    end

    add_index :email_stats, :email, :unique => true
    add_index :email_stats, :tag, :unique => true
  end
end
