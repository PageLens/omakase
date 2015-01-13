require 'rails_helper'

describe FolderInvitationSender do
  let(:folder_invitation) {create(:folder_invitation)}

  it "sends an email" do
    folder_invitation
    expect{FolderInvitationSender.new.perform(folder_invitation.id)}.to change(ActionMailer::Base.deliveries, :size)
  end
end
