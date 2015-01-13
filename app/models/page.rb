require 'open-uri'

class Page < ActiveRecord::Base
  include ActiveSupport::Benchmarkable
  include ActionView::Helpers::TextHelper

  serialize :fetch_error

  has_many :links, dependent: :destroy
  has_many :users, through: :links

  auto_strip_attributes :title, :description, :content

  before_validation :truncate_attributes
  after_commit lambda {PageFetcher.perform_async(self.id)}, on: :create
  after_commit lambda {link_ids.each {|lid| Indexer.perform_async(:update, 'Link', lid)}}, on: :update

  validates :url, presence: true, format: {with:URI.regexp}, length: {maximum:1024}, uniqueness: {case_sensitive: false}

  # Public: Fetches the HTML from the URL and populates the attributes.
  #
  # options - Hash for the options, see following:
  #           :force - If set to true, it will fetch the HTML even if it is recently fetched
  #
  # If there is an exception fetching the HTML, it logs the exception in the logger and set the fetch_error attribute.
  #
  # Returns self.
  def fetch(options={})
    response = nil
    if fetch_needed? or options[:force]
      begin
        benchmark "Fetching #{self.url}" do
          response = open(self.url, read_timeout: CONFIG[:page][:fetch_timeout], allow_redirections: :all)
          self.content_type = response.content_type
          if self.content_type =~ /text/
            doc = Nokogiri::HTML(response)
            self.html = doc.inner_html
            process_html if doc.html?
          end
        end
      rescue StandardError => e
        Rails.logger.warn("Error fetching #{self.url}:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
        self.fetch_error = {exception: e.class.name, message: e.message, backtrace: e.backtrace.join("\n") }
      ensure
        self.fetched_at = Time.zone.now
        response.try(:close!)
      end
    end
    self
  end

  # Public: Fetches the HTML from the URL, populates the attributes, and save the Page.
  #
  # options - Hash for the options, see following:
  #           :force - If set to true, it will fetch the HTML even if it is recently fetched
  #
  # Returns true if Page saved successfully, false otherwise
  def fetch!(options={})
    fetch(options)
    save!
  rescue ActiveRecord::StatementInvalid => e
    if e.message =~ /PG::CharacterNotInRepertoire/
      self.html = self.html.force_encoding('iso8859-1').encode('utf-8')
      save!
    else
      raise e
    end
  end

  # Public: Returns true if the Page needs to fetch
  def fetch_needed?
    self.fetched_at.nil? or self.fetched_at < CONFIG[:page][:refetch_interval].seconds.ago
  end

  # Public: Processes the HTML and set attributes from the HTML.
  #
  # Returns self.
  def process_html
    benchmark "Process HTML for #{self.url}" do
      doc = Readability::Document.new(self.html)
      html = doc.html
      self.title = content_for_open_graph_tag('og:title', html) || doc.title
      self.description =
        content_for_open_graph_tag('og:description', html) ||
        content_for_meta_tag('name="description"', html) ||
        html.xpath('//head/meta/@description', html).first.try(:content)
      image_url = content_for_open_graph_tag('og:image', html) || doc.images.first
      self.image_url = image_url if image_url =~ URI.regexp
      self.site_name = content_for_open_graph_tag('og:site_name', html) || get_url_domain.try(:humanize)
      self.content_html = doc.content.encode_from_charset!(doc.html.encoding)
      self.content = Nokogiri::HTML(self.content_html).text
    end
    self
  end

private
  # Private: Helper method to get the content for the OpenGraph tag.
  #
  # tag - Name of the OpenGraph tag.
  # html - Nokogiri HTML object containing the HTML.
  #
  # Returns content of the OpenGraph tag if found, nil otherwise.
  def content_for_open_graph_tag(tag, html)
    # html.xpath("//head/meta[@property='#{tag}']/@content").first.try(:content)
    content_for_meta_tag("property='#{tag}'", html)
  end

  # Private: Helper method to get the content from a Meta tag.
  #
  # attribute_selector - attribute to determine which meta tag to select. e.g. 'name="description"'
  # html - Nokogiri HTML object containing the HTML.
  #
  # Returns content of the meta tag if found, nil otherwise.
  def content_for_meta_tag(attribute_selector, html)
    html.xpath("//head/meta[@#{attribute_selector}]/@content").first.try(:content)
  end

  # Private: Returns the Domain name from the URL attribute.
  def get_url_domain
    uri = URI.parse(url)
    host = uri.host.downcase
    host.start_with?('www.') ? host[4..-1] : host
  end

  # Private: Truncates some attributes.
  def truncate_attributes
    self.title = truncate(title, length: 1000)
    self.site_name = truncate(site_name, length: 200)
    self
  end
end
