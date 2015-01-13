class FolderInvitation < ActiveRecord::Base
  enum status: [:created, :sent, :accepted]
  belongs_to :user
  belongs_to :folder
  belongs_to :recipient, class_name: 'User'

  validates :email, presence: true, email: true
  validates :message, length: {maximum: 2000}
  validates :folder_id, presence: true
  validate :ensure_user_has_access
  before_create :generate_code
  before_create :set_default_status
  after_commit :deliver, on: :create

  auto_strip_attributes :email, :message

  # Public: Accepts the FolderInvitation.
  #
  # invitee - User who accepts the FolderInvitation.
  #
  # returns true if saved.
  def accept_by!(invitee)
    Sharing.create!(creator_id: self.user_id, folder: self.folder, user: invitee) unless self.folder.accessible_by?(invitee)
    update!(status: :accepted, recipient: invitee)
  end

  # Public: Returns param.
  def to_param
    self.code
  end

  # Public: Sends the invitation email.
  def deliver
    FolderInvitationSender.perform_async(self.id)
  end

private
  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(16)
  end

  def set_default_status
    self.status ||= :created
  end

  def ensure_user_has_access
    errors.add(:user_id, "does not have permission") unless self.folder and self.folder.accessible_by?(self.user)
  end
end
