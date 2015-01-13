class Folder < ActiveRecord::Base
  has_many :links, dependent: :nullify
  has_many :sharings, dependent: :destroy
  has_many :shared_users, through: :sharings, source: :user
  has_many :subfolders, class_name: 'Folder', foreign_key: 'parent_folder_id'
  has_many :folder_invitations, dependent: :destroy
  belongs_to :user
  belongs_to :parent_folder, class_name: 'Folder'

  validates :name, presence: true, length: {maximum: 250}

  auto_strip_attributes :name

  class << self
    # Folders that User can access.
    #
    # user - User.
    #
    # Return ActiveRecord::Relation.
    #
    def for_user(user)
      where('user_id = :user_id OR id IN (:folder_ids)', {user_id: user.id, folder_ids: user.share_folder_ids}).order(:name)
    end
  end

  # Returns true if User has permission to access the Folder.
  def accessible_by?(user)
    self.user == user or Sharing.exists?(folder_id: self.id, user_id: user.id)
  end
end
