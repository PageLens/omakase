class UserMailerPreview < ActionMailer::Preview
  def folder_invitation
    folder_invitation = FolderInvitation.first || FactoryGirl.create(:folder_invitation)
    UserMailer.folder_invitation(folder_invitation)
  end
end
