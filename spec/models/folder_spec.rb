require 'rails_helper'

RSpec.describe Folder, :type => :model do
  subject {create(:folder)}

  it "creates Folder" do
    expect(subject).to be
  end

  it "has hierarchy" do
    parent_folder = create(:folder)
    subfolder = create(:folder)
    subject.parent_folder_id = parent_folder.id
    subject.subfolders << subfolder
    subject.save
    expect(subject.subfolders).to include subfolder
    expect(subject.parent_folder).to eq parent_folder
  end

  describe '.for_user' do
    it 'returns folders that User created' do
      subject
      expect(Folder.for_user(subject.user)).to include subject
    end

    it 'returns folders that shared to the User' do
      user = create(:user)
      Sharing.create(folder: subject, creator: subject.user, user: user)
      expect(Folder.for_user(user)).to include subject
    end
  end

  describe '#accessible_by?' do
    it 'is accessible for creator' do
      expect(subject).to be_accessible_by(subject.user)
    end

    it 'is accessible by shared Users' do
      user = create(:user)
      create(:sharing, user: user, creator: subject.user, folder: subject)
      expect(subject).to be_accessible_by(user)
    end

    it 'is not accessible by non-creator and non-shared Users' do
      user = create(:user)
      expect(subject).to_not be_accessible_by(user)
    end
  end
end
