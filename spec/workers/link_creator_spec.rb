require 'rails_helper'

describe LinkCreator do
  let(:user) {create(:user)}
  let(:valid_attributes) {{url: 'http://example.com', name: 'Test', user_id: user.id, title: 'Example', keywords: ['alpha', 'beta'], source: Link::SOURCES[:facebook], source_id: '123', source_uid: 'uid', saved_by: :friend}}

  it 'returns nil if options[:user_id] is blank' do
    expect(subject.perform(valid_attributes.except(:user_id))).to be_nil
  end

  it 'returns nil if options[:url] is blank' do
    expect(subject.perform(valid_attributes.except(:url))).to be_nil
  end

  context 'Page does not exist' do
    it 'creates a new Link and a new Page' do
      expect {
        expect {subject.perform(valid_attributes)}.to change{Page.count}.by(1)
      }.to change{Link.count}.by(1)
    end
  end

  context 'Page exists' do
    let(:page) {create(:page, url: valid_attributes[:url])}
    before { page }
    context 'Link does not exist' do
      it 'creates a new Link and does not create a new Page' do
        expect {
          expect {subject.perform(valid_attributes)}.to_not change{Page.count}
        }.to change{Link.count}.by(1)
      end
    end

    context 'Link exists' do
      let(:link) {create(:link, user_id: user.id, page_id: page.id)}
      before { link }
      it 'does not create a new Link nor a new Page' do
        expect {
          expect{subject.perform(valid_attributes)}.to_not change{Page.count}
        }.to_not change{Link.count}
      end

      it 'updates the attributes if the existing Link saved_by is not :me' do
        link.update!(saved_by: :friend, note: "Old Note")
        subject.perform(valid_attributes.merge(saved_by: :me, note: "New Note").except(:source_uid))
        link.reload
        expect(link.saved_by).to eq 'me'
        expect(link.note).to eq "New Note"
      end

      it 'does not update the saved_by if the exist Link saved_by is :me and the new saved_by is :friend' do
        link.update!(saved_by: :me)
        subject.perform(valid_attributes.merge(saved_by: :friend))
        link.reload
        expect(link.saved_by).to eq 'me'
        expect(link.source_uid).to be_nil
      end

      it 'updates the attributes if saved_by is :me' do
        link.update!(saved_by: :me, note: "Old Note")
        subject.perform(valid_attributes.merge(saved_by: :me, note: "New Note").except(:source_uid))
        link.reload
        expect(link.note).to eq "New Note"
      end
    end
  end

  context 'Folders' do
    it "assigns Folder to Link" do
      link = subject.perform(valid_attributes.merge(folders: ['folder']))
      folder = link.folder
      expect(folder).to be
      expect(folder.name).to eq 'folder'
      expect(folder.user).to eq user
    end

    it "assigns multiple Folders to Link" do
      link = subject.perform(valid_attributes.merge(folders: ['parent', 'children']))
      folder = link.folder
      expect(folder).to be
      expect(folder.name).to eq 'children'
      expect(folder.user).to eq user
      parent_folder = folder.parent_folder
      expect(parent_folder).to be
      expect(parent_folder.name).to eq 'parent'
      expect(parent_folder.user).to eq user
    end

    context 'with non-existing Folders' do
      it "creates a Folder" do
        expect{subject.perform(valid_attributes.merge(folders: ['folder']))}.to change(Folder, :count).by(1)
      end

      it "creates a Folder if there is another Folder with same name" do
        create(:folder, name: 'folder')
        expect{subject.perform(valid_attributes.merge(folders: ['folder']))}.to change(Folder, :count).by(1)
      end
    end

    context 'with existing Folders' do
      it "does not creates a Folder" do
        create(:folder, name: 'folder', user: user)
        expect{subject.perform(valid_attributes.merge(folders: ['folder']))}.to_not change(Folder, :count)
      end
    end
  end
 end
