class BookmarkFileExporter
  # Public: Exports links in Netscape Bookmarks HTML format.
  #
  # links - Array of Links or Link Class.
  #
  #
  def export(links)
    builder = Markio::Builder.new
    each_method = links.respond_to?(:find_each) ? :find_each : :each
    links.send(each_method) {|l| export_link(builder, l)}
    builder.build_string
  end

private

  # Private: Converts each bookmark into DT tag.
  #
  def export_link(builder, link)
    folders = []
    folders << link.folder.name if link.folder
    folders = folders + link.keywords if link.keywords.present?
    builder.bookmarks << Markio::Bookmark.create({
      title: link.name,
      href: link.url,
      folders: folders.present? ? folders : nil,
      add_date: link.saved_at
    })
  end

end
