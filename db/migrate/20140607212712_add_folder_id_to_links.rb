class AddFolderIdToLinks < ActiveRecord::Migration
  def change
    add_reference :links, :folder, index: true
  end
end
