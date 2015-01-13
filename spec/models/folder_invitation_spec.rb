require 'rails_helper'

RSpec.describe FolderInvitation, :type => :model do
  subject {create(:folder_invitation)}

  it 'should generate code and status upon creation' do
    expect(subject.code).to be_present
    expect(subject.status).to eq 'created'
  end

  it 'does not allow User does not have access to Folder to create a FolderInvitation' do
    folder_invitation = build(:folder_invitation)
    folder_invitation.user = create(:user)
    expect(folder_invitation).to_not be_valid
  end

  describe '#accept_by!' do
    let(:recipient) {create(:user)}

    it 'creates a Sharing' do
      expect{subject.accept_by!(recipient)}.to change{Sharing.count}.by(1)
      sharing = Sharing.last
      expect(sharing.folder).to eq subject.folder
      expect(sharing.creator).to eq subject.user
      expect(sharing.user).to eq recipient
    end

    it 'does not create a Sharing if recipient has access to this Folder already' do
      invitation = create(:folder_invitation)
      invitation.accept_by!(recipient)
      expect{create(:folder_invitation, folder: invitation.folder).accept_by!(recipient)}.to_not change{Sharing.count}
    end

    it 'updates the status and recipient' do
      subject.accept_by!(recipient)
      expect(subject.status).to eq 'accepted'
      expect(subject.recipient).to eq recipient
    end
  end

  describe '#deliver' do
    it 'schedules a background job to send the invitation' do
      subject
      expect{subject.deliver}.to change(FolderInvitationSender.jobs, :size).by(1)
    end
  end
end
