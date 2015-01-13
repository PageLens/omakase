class Link < ActiveRecord::Base
  include Elasticsearch::Model

  SOURCES = {web: "web", facebook: "facebook", twitter: "twitter", email: "email", import: "import"}

  attr_accessor :url
  enum saved_by: [:me, :friend]

  has_many :clicks, dependent: :destroy
  belongs_to :user
  belongs_to :page, counter_cache: true
  belongs_to :folder, counter_cache: true

  # Set up callbacks for updating the index on model changes
  before_validation :find_or_create_page_from_url
  before_create :set_default_saved_at
  after_commit lambda { Indexer.perform_async(:index,  self.class.to_s, self.id) }, on: :create
  after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
  after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy
  after_touch  lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }

  validates :name, length: {maximum:1024}
  validates :note, length: {maximum:10000}
  validates :source, inclusion: {in: SOURCES.values}
  validates :page_id, uniqueness: {scope: :user_id}
  validates :url, format: {with:URI.regexp}, length: {maximum:1024} if Proc.new {|l| l.page_id.nil?}
  validate :ensure_folder_is_accessible_by_user

  auto_strip_attributes :name, :note

  mapping dynamic: 'strict' do
    indexes :page do
      indexes :title, type: 'multi_field' do
        indexes :title, analyzer: 'snowball'
        indexes :tokenized, analyzer: 'simple'
      end
      indexes :site_name, index: 'not_analyzed'
      indexes :image_url, index: 'not_analyzed'
      indexes :description, analyzer: 'snowball'
      indexes :content, type: 'multi_field' do
        indexes :description, analyzer: 'snowball'
        indexes :tokenized, analyzer: 'simple'
      end
    end
    indexes :id, type: 'integer', index: 'not_analyzed'
    indexes :name, boost: 2.0, similarity: 'BM25'
    indexes :keywords, index: 'not_analyzed'#analyzer: 'keyword'
    indexes :note, analyzer: 'snowball'
    indexes :source,  index: 'not_analyzed'
    indexes :user_id, type: 'integer', index: 'not_analyzed'
    indexes :folder_id, type: 'integer', index: 'not_analyzed'
    indexes :saved_by, index: 'not_analyzed'
    indexes :saved_at, type: 'date'
    indexes :creation_epoch, type: 'integer', index: 'not_analyzed'
  end

  class << self
    # Public: Filters Links for User.
    #
    # user - User.
    # params - Hash options.
    #          folder_id: ID of the Folder where the Links belongs to (optional).
    #
    # Returns ActiveRecord relation.
    #
    def for_user(user, params={})
      folder_ids = Folder.for_user(user).pluck(:id)
      r = where('user_id = :user_id OR folder_id IN (:folder_ids)', {user_id: user.id, folder_ids: folder_ids})
      r = r.where(folder_id: params[:folder_id]) if params[:folder_id].present?
      r
    end

    # Public: Searches Links, include highlights in response.
    #
    # See search_definition for options.
    #
    # Returns Elasticsearch::Model::Response::Response.
    #
    # e.g. search_response = Link.search(query: 'Test')
    #      facets = search_response.response['facets']
    #      records = search_response.records
    #      results = search_response.results
    #      highlight = results.first.try(:highlight)
    #      search_response.each_with_hit {|record, result| puts "* #{record.title}: #{result._score}"}
    #
    def search(options={})
      __elasticsearch__.search(search_definition(options))
    end

    # Public: Searches Links for particular User. If no search Query, then returns all Links accessible by the User.
    #
    # user - User who performs the search.
    # params - Hash of parameters:
    #          query: Query String (optional).
    #          folder_id: Filter on Folder ID (optional).
    #          source: Filter on source (optional).
    #          site_name: Filter on the name of the site (optional).
    #          since: ISO8601 String of Time that the Links saved since (optional).
    #          saved_by: 'me' or 'friend'. Ignore if not specified (optional).
    #          sort: Field to sort on (default: :saved_at).
    #          folder_id: ID of the Folder where the Links belongs to (optional).
    #          per_page: Links per page (default: 10).
    #          page: Page Number (default: 1).
    #
    # Returns Elastic Search Response [Elasticsearch::Model::Response::Response].
    #
    def search_for_user(user, params={})
      folder_ids = params[:folder_id].present? ? [params[:folder_id]] : user.share_folder_ids
      options = params.with_indifferent_access.merge(user_id: user.id, folder_ids: folder_ids)
      search(options)
    end

    # Public: Search DSL Hash for User, include highlights in response.
    #
    # options - Search options:
    #           query: Query String (optional).
    #           user_id: User ID (required).
    #           folder_ids: Array of Folder ID that User has access to (optional).
    #           folder_id: Filter on Folder ID (optional).
    #           source: Filter on source (optional).
    #           site_name: Filter on the name of the site (optional).
    #           since: ISO8601 String of Time that the Links saved since (optional).
    #           saved_by: 'me' or 'friend'. Ignore if not specified (optional).
    #           sort: Field to sort on (default: :saved_at).
    #           decay: Scores decays over time (default: true).
    #
    # Returns Elastic Search DSL Hash.
    #
    def search_definition(options={})
      options = options.reverse_merge(decay: true).with_indifferent_access
      query = options[:query]

      # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
      #
      __set_filters = lambda do |key, f|
        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and]  |= [f]

        if @search_definition[:facets][key.to_sym]
          @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
          @search_definition[:facets][key.to_sym][:facet_filter][:and]  |= [f]
        end
      end

      @search_definition = {
        query: {bool: {must: [], should: []}},
        highlight: {
          pre_tags: ['<mark>'],
          post_tags: ['</mark>'],
          fields: {
            'name'=>{number_of_fragments: 0},
            'note'=>{fragment_size: 50},
            'page.title'=>{number_of_fragments: 0},
            'page.content'=>{fragment_size: 50}
          }
        },
        filter: {},
        facets: {
          keywords: {
            terms: {
              field: 'keywords',
              all_terms: true,
              size: 10
            },
            facet_filter: {}
          },
          folder_id: {
            terms: {
              field: 'folder_id'
            },
            facet_filter: {}
          },
          source: {
            terms: {
              field: 'source'
            },
            facet_filter: {}
          },
          site_name: {
            terms: {
              field: 'page.site_name'
            },
            facet_filter: {}
          },
          saved_by: {
            terms: {
              field: 'saved_by'
            },
            facet_filter: {}
          }
        }
      }

      if query
        @search_definition[:query][:bool][:must] << {
          multi_match: {
            query: query,
            fields: ['name^10', 'note^2', 'keywords^5', 'page.title^10', 'page.content'],
            operator: 'and'
          }
        }
        @search_definition[:suggest] = {
          text: query,
          suggest_title: {
            term: {
              field: 'page.title.tokenized',
              suggest_mode: 'always'
            }
          },
          suggest_body: {
            term: {
              field: 'page.content.tokenized',
              suggest_mode: 'always'
            }
          }
        }
      else
        @search_definition[:sort]  = {saved_at: 'desc'}
      end

      if options[:user_id].present?
        @search_definition[:query][:bool][:should] << {
          term: {user_id: options[:user_id]}
        }
        @search_definition[:query][:bool][:minimum_should_match] = 1
      end

      if options[:folder_ids]
        @search_definition[:query][:bool][:should] << {
          terms: {
            folder_id: options[:folder_ids],
            minimum_should_match: 1
          }
        }
        @search_definition[:query][:bool][:minimum_should_match] = 1
      end

      if options[:folder_id].present?
        f = {term: {folder_id: options[:folder_id]}}
        __set_filters.(:keywords, f)
        __set_filters.(:source, f)
        __set_filters.(:site_name, f)
        __set_filters.(:since, f)
        __set_filters.(:saved_by, f)
      end

      if options[:source].present?
        f = {term: {source: options[:source]}}
        __set_filters.(:folder_id, f)
        __set_filters.(:keywords, f)
        __set_filters.(:site_name, f)
        __set_filters.(:since, f)
        __set_filters.(:saved_by, f)
      end

      if options[:site_name].present?
        f = {term: {'page.site_name' => options[:site_name]}}
        __set_filters.(:folder_id, f)
        __set_filters.(:keywords, f)
        __set_filters.(:source, f)
        __set_filters.(:since, f)
        __set_filters.(:saved_by, f)
      end

      if options[:since].present?
        f = {range: {saved_at: {gte: Time.zone.parse(options[:since].to_s)}}}
        __set_filters.(:folder_id, f)
        __set_filters.(:keywords, f)
        __set_filters.(:source, f)
        __set_filters.(:site_name, f)
        __set_filters.(:saved_by, f)
      end

      if options[:saved_by].present?
        f = {term: {saved_by: options[:saved_by]}}
        __set_filters.(:folder_id, f)
        __set_filters.(:keywords, f)
        __set_filters.(:source, f)
        __set_filters.(:site_name, f)
        __set_filters.(:since, f)
      end

      if options[:keywords].present?
        f = {term: {keywords: options[:keywords]}}
        __set_filters.(:folder_id, f)
        __set_filters.(:source, f)
        __set_filters.(:site_name, f)
        __set_filters.(:since, f)
        __set_filters.(:saved_by, f)
      end

      if options[:sort].present?
        @search_definition[:sort]  = {options[:sort] => 'desc'}
        @search_definition[:track_scores] = true
      end

      if options[:decay] and query.present?
        @search_definition[:query] = {
          function_score: {
            functions: [{
              gauss: {
                creation_epoch: {
                  origin: Time.zone.now.to_i,
                  scale: CONFIG[:link][:decay]
                }
              }
            }],
            query: @search_definition[:query],
            score_mode: 'multiply'
          }
        }
      end

      @search_definition
    end

  end

  # Public: Returns saved_at in Epoch.
  def creation_epoch
    saved_at.try(:to_i)
  end

  # Public: JSON serialization for Elasticsearch.
  def as_indexed_json(options={})
    self.as_json(
      methods: [:creation_epoch],
      include: {
        page: {only: [:url, :title, :site_name, :description, :content, :image_url]},
      }
    )
  end

  # Public: Returns the URL of the Link.
  def url
    self.page.try(:url) || @url
  end

  # Public: Sets URL attribute, appends http protocol if missing.
  #
  # u - URI String.
  #
  def url=(u)
    u = u.try(:strip)
    u = "http://#{u}" if u.present? and u !~ /^\w+:\/\//
    if self.page
      self.page.url = u
    else
      @url = u
    end
  end

  # Public: Returns the name of the Link. If it is not set, it will use the title from the Page.
  def name
    read_attribute(:name) || self.page.try(:title) || self.url
  end

  # Public: Returns keywords in comma seperated string.
  def tags(separator=", ")
    self.keywords.try(:join, separator)
  end

  # Public: Sets keywords.
  #
  # ts - Comma separated keywords String.
  #
  def tags=(ts)
    keywords = ts && ts.split(/\,/).map(&:strip)
    self.keywords = keywords.blank? ? nil : keywords
  end

private

  def set_default_saved_at
    self.saved_at ||= Time.zone.now
  end

  # Private: Finds the Page by URL or create the Page using the URL.
  def find_or_create_page_from_url
    if self.page_id.nil? and @url.present?
      self.page_id = (Page.where(url: @url).first || Page.create!(url: @url)).id
    end
  end

  def ensure_folder_is_accessible_by_user
    if self.folder
      errors.add(:folder_id, "is not accessible by the user who saved this link") unless self.folder.accessible_by?(self.user)
    end
  end

end
