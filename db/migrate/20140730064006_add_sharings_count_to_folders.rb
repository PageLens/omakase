class AddSharingsCountToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :sharings_count, :integer, default: 0
  end
end
