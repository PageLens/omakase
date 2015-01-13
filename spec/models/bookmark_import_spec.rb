require 'rails_helper'

RSpec.describe BookmarkImport, :type => :model do
  let(:user) {create(:user)}
  let(:bookmark_file) {read_fixture_file('bookmark_file.html')}

  it "should returns attributes to create Link" do
    bookmarks = Markio::parse(bookmark_file)
    bookmark = bookmarks.first
    attrs = subject.bookmark_to_link_attributes(bookmark)
    expect(attrs[:name]).to eq "Maps"
    expect(attrs[:url]).to eq "http://maps.google.com/"
    expect(attrs[:folders]).to eq ["Bookmarks Bar"]
    expect(attrs[:keywords]).to eq ["Bookmarks Bar"]
  end

  it "should create background jobs to create the Link" do
    bookmark_import = build(:bookmark_import, user: user, bookmark_file: File.open("#{fixture_path}/bookmark_file.html"))
    expect{bookmark_import.save}.to change(LinkCreator.jobs, :size)
    expect(bookmark_import.status).to eq "done"
  end
end
