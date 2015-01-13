require "rails_helper"

RSpec.describe UserMailer, :type => :mailer do
  describe "folder_invitation" do
    let(:folder_invitation) {create(:folder_invitation)}
    let(:mail) { UserMailer.folder_invitation(folder_invitation.id) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t('user_mailer.folder_invitation.subject'))
      expect(mail.to).to eq([folder_invitation.email])
      expect(mail.from).to eq([CONFIG[:mailer][:notification_email]])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(folder_invitation.folder.name)
    end
  end

end
