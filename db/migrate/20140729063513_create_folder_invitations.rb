class CreateFolderInvitations < ActiveRecord::Migration
  def change
    create_table :folder_invitations do |t|
      t.references :user, index: true, null: false
      t.references :folder, index: true, null: false
      t.string :email
      t.text :message
      t.integer :status, default: 0
      t.string :code, null: false
      t.integer :recipient_id

      t.timestamps
    end
    add_index :folder_invitations, :code, unique: true
    add_index :folder_invitations, :status
    add_index :folder_invitations, :recipient_id
  end
end
