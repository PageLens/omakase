require 'rails_helper'

RSpec.describe Sharing, :type => :model do
  subject {create(:sharing, user: user, folder: folder)}
  let(:user) {create(:user)}
  let(:folder) {create(:folder)}

  it "should return the correct associations" do
    creator = subject.creator
    expect(creator.created_sharings).to include subject
    expect(folder.shared_users).to include user
  end

  it "should not allow User to share a folder to himself" do
    sharing = build(:sharing, user: user, creator: user)
    expect(sharing).to_not be_valid
  end

  it "should only allow User has access to share a folder" do
    subject
    another_user = create(:user)
    sharing = build(:sharing, user: another_user, creator: user, folder: folder)
    sharing = build(:sharing, user: user, creator: another_user, folder: folder)
    expect(sharing).to_not be_valid
  end

end
