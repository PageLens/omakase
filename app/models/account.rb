class Account < ActiveRecord::Base
  PROVIDERS = {facebook:'facebook', twitter: 'twitter'}
  FACEBOOK_LINK_APP_ID = "app_2309869772"
  FACEBOOK_NEWS_FEED_PATH = "me/home"
  FACEBOOK_LINKS_PATH = "me/links"

  belongs_to :user
  serialize :auth_hash
  store_accessor :info, :name, :urls, :email
  store_accessor :credentials, :token, :secret, :expires_at, :expires
  # store_accessor :metadata

  after_commit lambda {LinksFetcher.perform_async(self.id)}, on: :create

  validates :provider, presence: true, :uniqueness => {scope: :user_id}, inclusion: {in: PROVIDERS.values}
  validates :uid, presence: true, uniqueness: {scope: :provider}

  # Public: Returns when the Account expires
  def expires_at
    credentials["expires_at"] and Time.zone.at(credentials["expires_at"].to_i)
  end

  # Public: Returns True if the Account will expire.
  def expires?
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(credentials["expires"])
  end

  # Public: Returns True if the Account is expired.
  def expired?
    expires? and Time.zone.now >= self.expires_at
  end

  # Public: Fetches Links from Facebook and creates Links.
  #
  # options: Option Hash.
  #          per_page: Entries per page (default: 25).
  #          since: Last time successfully fetched from Facebook (default: @fetched_at).
  #
  # Returns if the record is updated with the latest fetched_at.
  #
  def fetch_links!(options={})
    if self.credentials and not expired?
      now = Time.zone.now
      case self.provider
      when PROVIDERS[:facebook] then fetch_from_facebook!(options)
      when PROVIDERS[:twitter] then fetch_from_twitter!(options)
      else raise "Don't know how to fetch links"
      end
      self.fetched_at = now
      save!
    end
  end

  # Public: Fetches Links from Facebook and creates Links.
  #
  # options: Option Hash.
  #          per_page: Entries per page (default: 25).
  #          since: Last time successfully fetched from Facebook (default: @fetched_at).
  #
  # Returns Array of LinkCreator jobs.
  #
  def fetch_from_facebook!(options={})
    jobs = []
    fetch_url_likes.each do |url|
      jobs << LinkCreator.perform_async(
        url: url,
        source: Link::SOURCES[:facebook],
        user_id: self.user_id,
        saved_by: :me
      )
    end

    options = options.with_indifferent_access.reverse_merge(per_page: 25, now: Time.zone.now, since: self.fetched_at).compact
    fetch_options = {per_page: options[:per_page], since: options[:since].try(:to_i)}
    fetch_facebook_links(fetch_options) {|o| jobs <<  LinkCreator.perform_async(link_attributes_for_facebook_object(o))}
    # fetch_facebook_news_feed(fetch_options) {|o| LinkCreator.perform_async(link_attributes_for_facebook_object(o))}
    jobs
  end

  # Public: Uses Facebook Graph API to fetch links that the User posted
  def fetch_facebook_links(options={}, &block)
    fetch_facebook_objects(FACEBOOK_LINKS_PATH, {limit: options[:per_page], since: options[:since]}, &block)
  end

  # Public: Uses Facebook Graph API to fetch links in Activity feed.
  def fetch_facebook_news_feed(options={}, &block)
    objs = []
    # This fetches objects only posted by FB Link app.
    # fetch_facebook_objects(FACEBOOK_NEWS_FEED_PATH, filter: FACEBOOK_LINK_APP_ID, limit: options[:per_page], since: options[:since]) do |obj|
    # This fetches all Links.
    fetch_facebook_objects(FACEBOOK_NEWS_FEED_PATH, limit: options[:per_page]) do |obj|
    # fetch_facebook_objects(FACEBOOK_NEWS_FEED_PATH, limit: options[:per_page], since: options[:since]) do |obj|
      # status_type: {mobile_status_update, created_note, added_photos, added_video, shared_story, created_group, created_event, wall_post, app_created_story, published_story, tagged_in_photo, approved_friend}
      # type: {link, status, photo, video}
      if block_given? and
        (obj['status_type'] == 'shared_story' or obj['status_type'] == 'published_story') and
        obj['type'] == 'link'
        if options[:only_liked_by_me]
          obj['likes']['data'].each do |d|
            if d['id'] == self.uid
              objs << obj
              block.call(obj)
            end
          end if obj['likes'] and obj['likes']['data']
        else
          objs << obj
          block.call(obj)
        end
      end
    end
    objs
  end

  # Public: Fetches Links that the User recent liked.
  #
  # Returns Array of URLs.
  #
  def fetch_url_likes
    facebook_client.fql_query("select url from url_like where user_id = me()").map{|d| d["url"]}
  rescue Koala::Facebook::AuthenticationError => e
    update_attribute(:credentials, nil)
    raise e
  end

  # Public: Fetches Tweets from Twitter and creates Links.
  #
  # options: Option Hash.
  #          per_page: Entries per page (default: 200).
  #          timeline_since_id: Returns results with an ID greater than (that is, more recent than) the specified ID.  (default: @metadata['timeline_since_id']).
  #          favorites_since_id: Returns results with an ID greater than (that is, more recent than) the specified ID.  (default: @metadata['favorites_since_id']).
  #
  # Returns Array of LinkCreator jobs.
  #
  def fetch_from_twitter!(options={})
    jobs = []
    timeline_since_id = self.metadata && self.metadata['timeline_since_id'].try(:to_i)
    favorites_since_id = self.metadata && self.metadata['favorites_since_id'].try(:to_i)
    options = options.with_indifferent_access.reverse_merge(
      per_page: 200,
      timeline_since_id: timeline_since_id,
      favorites_since_id: favorites_since_id).compact
    fetch_twitter_timeline({count: options[:per_page], since_id: options[:timeline_since_id].try(:to_i)}.compact) do |tweet|
      timeline_since_id = tweet.id if timeline_since_id.nil? or timeline_since_id < tweet.id
      jobs << LinkCreator.perform_async(link_attributes_for_tweet(tweet)) if tweet.uris.present?
    end
    fetch_twitter_favorites({count: options[:per_page], since_id: options[:favorites_since_id].try(:to_i)}.compact) do |tweet|
      favorites_since_id = tweet.id if favorites_since_id.nil? or favorites_since_id < tweet.id
      jobs << LinkCreator.perform_async(link_attributes_for_tweet(tweet)) if tweet.uris.present?
    end
    self.metadata ||= {}
    self.metadata['timeline_since_id'] = timeline_since_id
    self.metadata['favorites_since_id'] = favorites_since_id
    jobs
  end

  def fetch_twitter_timeline(options={}, &block)
    options = options.merge(count: 200, include_rts: true)
    collect_tweets do |max_id|
      options[:max_id] = max_id unless max_id.nil?
      twitter_client.user_timeline(self.uid.to_i, options).tap do |tweets|
        tweets.each {|t| block.call(t)} if block_given?
      end
    end
  end

  def fetch_twitter_favorites(options={}, &block)
    options = options.merge(count: 200, include_entities: true)
    collect_tweets do |max_id|
      options[:max_id] = max_id unless max_id.nil?
      twitter_client.favorites(options).tap do |tweets|
        tweets.each {|t| block.call(t)} if block_given?
      end
    end
  end

private

  # Private: Returns Facebook::API Object.
  def facebook_client
    @graph ||= Koala::Facebook::API.new(credentials["token"])
  end

  # Private: Returns Twitter::REST::Client.
  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = Rails.application.secrets.twitter["api_key"]
      config.consumer_secret     = Rails.application.secrets.twitter["secret"]
      config.access_token        = self.token
      config.access_token_secret = self.secret
    end
  end

  # Private: Fetched Facebook Graph Objects.
  #
  # path - REST API path.
  # params - Hash of parameters for API requests.
  # block - If passed, it calls the block with each Array of Facebook Objects
  #
  # Returns Array of Facebook Objects.
  #
  def fetch_facebook_objects(path, params, &block)
    links = []
    params = params.with_indifferent_access.compact
    loop do
      Rails.logger.debug "* GET #{path} with #{params.inspect}"
      l = facebook_client.get_object(path, params)
      break if l.blank? or l.next_page_params.nil?
      l.each {|fb_obj| block.call(fb_obj)} if block_given?
      links.concat(l)
      params = params.merge(l.next_page_params[1])
    end
    links
  rescue Koala::Facebook::AuthenticationError => e
    update_attribute(:credentials, nil)
    raise e
  end

  # Private: Helper function to collect Tweets.
  def collect_tweets(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_tweets(collection, response.last.id - 1, &block)
  rescue Twitter::Error::Unauthorized => e
    update_attribute(:credentials, nil)
    raise e
  end

  # Private: Returns attributes to create a Link from Tweet.
  #
  # tweet - Tweet object.
  #
  # Returns Hash of attributes. Nil if no uris in the Tweet.
  #
  def link_attributes_for_tweet(tweet)
    if tweet.uris.present?
      {
        url: tweet.uris.first.expanded_url,
        note: tweet.text,
        source: Link::SOURCES[:twitter],
        source_id: tweet.id,
        source_uid: tweet.user.id,
        saved_at: tweet.created_at,
        user_id: self.user_id
      }
    end
  end

  # Private: Returns attributes to create a Link from Facebook Object.
  #
  # fb_link - Facebook link object.
  #
  # Returns Hash of attributes.
  #
  def link_attributes_for_facebook_object(fb_link)
    {
      url: fb_link['link'],
      title: fb_link['name'],
      description: fb_link['description'],
      image_url: fb_link['picture'],
      site_name: fb_link['caption'],
      name: fb_link['name'],
      note: fb_link['message'],
      source: Link::SOURCES[:facebook],
      source_id: fb_link['id'],
      source_uid: fb_link['from']['id'],
      saved_by: (fb_link['from']['id'] == self.uid) ? :me : :friend,
      saved_at: Time.zone.parse(fb_link['created_time']),
      user_id: self.user_id
    }
  end
end
