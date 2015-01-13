class CreateEmailDeliveries < ActiveRecord::Migration
  def change
    create_table :email_deliveries do |t|
      t.references :email_stat, :null => false
      t.string :tracking_code, :null => false
      t.string :subject
      t.datetime :read_at
      t.datetime :clicked_at
      t.datetime :created_at
    end
    add_index :email_deliveries, :email_stat_id
    add_index :email_deliveries, :tracking_code, :unique => true
  end
end
