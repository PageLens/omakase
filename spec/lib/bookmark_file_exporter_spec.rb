require 'rails_helper'
require "bookmark_file_exporter"

describe BookmarkFileExporter do
  let(:folder) {create(:folder)}
  let(:link) {create(:link, folder: folder, user: folder.user, keywords: ['k1'])}

  it "should output links into HTML" do
    output = BookmarkFileExporter.new.export([link])
    bookmarks = Markio::parse(output)
    expect(bookmarks.length).to eq 1
    bookmark = bookmarks.first
    expect(bookmark.title).to eq link.name
    expect(bookmark.href).to eq link.url
    expect(bookmark.folders).to include folder.name
    expect(bookmark.folders).to include 'k1'
    expect(bookmark.add_date.to_i).to eq link.saved_at.to_i
  end
end
