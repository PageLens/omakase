class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.references :user, index: true, null: false
      t.string :provider, null: false
      t.string :uid, null: false
      t.hstore :info
      t.hstore :credentials
      t.hstore :metadata
      t.text :auth_hash
      t.datetime :fetched_at

      t.timestamps
    end

    add_index :accounts, [:provider, :uid], unique: true
    add_index :accounts, :fetched_at
  end
end
