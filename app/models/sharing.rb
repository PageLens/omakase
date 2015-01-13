class Sharing < ActiveRecord::Base
  belongs_to :folder, counter_cache: true
  belongs_to :user
  belongs_to :creator, class_name: 'User'

  validate :ensure_creator_has_permission_to_share
  validate :ensure_different_creator_and_user

private
  def ensure_creator_has_permission_to_share
    errors.add(:creator_id, "does not have permission") unless folder.accessible_by?(creator)
  end

  # Private: Ensures Creator and User are the same person.
  def ensure_different_creator_and_user
    errors.add(:user_id, "can't be same as creator") if user == creator
  end
end
