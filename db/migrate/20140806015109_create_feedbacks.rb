class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :email, null: false
      t.string :subject, null: false
      t.text :description
      t.text :note

      t.timestamps
    end
  end
end
