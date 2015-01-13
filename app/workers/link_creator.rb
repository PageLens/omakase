require 'url_utils'

class LinkCreator
  include Sidekiq::Worker
  sidekiq_options queue: :medium, retry: 3, backtrace: true

  # Public: Creates a Link from attributes.
  #
  # attributes - Hash of Attribute to create the Link:
  #              url: URL of the Page (required).
  #              title: Title of the Page (optional).
  #              description: Description of the Page (optional).
  #              folders: Array of folder names (optional).
  #              image_url: Image URL for the Page (optional).
  #              site_name: Site name for the Page (optional).
  #              name: Name of the Link (optional).
  #              note: Note for the Link (optional).
  #              tags: Comma seperated keywords (optional).
  #              keywords: Array of keywords for the Link (optional).
  #              source: Source of the Link (required).
  #              source_id: ID from the source system (optional).
  #              source_uid: User ID of the source system (optional).
  #              saved_by: Origined by the User (:me) or his friend (:friend) (default: :me)
  #              saved_at: Date when this Link is created (optional).
  #              user_id: User ID (required).
  #
  # Returns the created Link.
  #
  def perform(attributes)
    return nil if attributes.nil?
    attributes = attributes.with_indifferent_access.reverse_merge(saved_by: :me)
    return nil if attributes[:url].blank? or attributes[:user_id].blank?
    attributes[:url] = UrlUtils.append_protocol(attributes[:url])
    page_attr = attributes.extract!(:url, :title, :description, :image_url, :site_name)
    page = Page.where(url: page_attr[:url]).first || Page.create!(page_attr)

    folders = attributes.delete(:folders)
    if folders.present?
      folders = Array.wrap(folders)
      parent_folder = nil
      folder_id = nil
      folders.each do |f|
        folder = Folder.where(user_id: attributes[:user_id], name: f).first_or_initialize
        folder.update(parent_folder_id: folder_id) if folder.new_record?
        folder_id = folder.id
      end
      attributes[:folder_id] = folder_id
    end

    link = Link.where(page_id: page.id, user_id: attributes.delete(:user_id)).first_or_initialize
    if attributes[:saved_by].to_s == 'me' or link.new_record?
      link.assign_attributes(attributes)
    end
    link.save!
    link
  end
end
