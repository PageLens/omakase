class FolderInvitationSender
  include Sidekiq::Worker
  sidekiq_options queue: :medium, retry: 3, backtrace: true

  # Public: Sends out the FolderInvitation.
  #
  # folder_invitation_id: ID of FolderInvitation.
  #
  def perform(folder_invitation_id, options={})
    UserMailer.folder_invitation(folder_invitation_id).deliver
  end
end
