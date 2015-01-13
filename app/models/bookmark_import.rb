class BookmarkImport < ActiveRecord::Base
  mount_uploader :bookmark_file, BookmarkFileUploader
  enum status: [:created, :processing, :done]

  belongs_to :user

  validates :bookmark_file, presence: true
  after_create :process!

  # Public: Processes the bookmark file and convert the bookmarks to Links.
  def process!
    self.update(status: :processing)
    Markio::parse(File.open(bookmark_file.current_path)).each do |bookmark|
      LinkCreator.perform_async(bookmark_to_link_attributes(bookmark))
    end
    self.update(status: :done)
  end

  # Public: Returns the attributes for LinkCreator to create a Link.
  #
  # bookmark - Hash returning from Markio.
  #
  # Returns Hash.
  #
  def bookmark_to_link_attributes(bookmark)
    {
      name: bookmark.title,
      url: bookmark.href,
      saved_at: bookmark.add_date,
      folders: bookmark.folders,
      source: Link::SOURCES[:import],
      keywords: bookmark.folders,
      user_id: self.user_id
    }
  end

end
