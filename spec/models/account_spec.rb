require 'rails_helper'

describe Account do
  subject {create(:account)}

  it 'should returns expires_at' do
    expect(subject.expires_at).to be
  end

  it "should schedule background job to fetch Links when created" do
    expect{subject}.to change{LinksFetcher.jobs.size}
  end

  it 'should tell if the Account will expire' do
    expect(subject).to be_expires
  end

  describe '#expired?' do
    it 'should return true if the Account has expired' do
      subject.credentials["expires_at"] = Time.zone.now
      expect(subject).to be_expired
    end

    it 'should return false if the Account has not expired' do
      subject.credentials["expires_at"] = 1.day.from_now
      expect(subject).to_not be_expired
    end
  end

  context 'twitter' do
    subject {create(:account, provider: 'twitter', secret: 'secret')}
    let(:empty_response_file) {read_fixture_file('twitter_empty_output.txt')}
    let(:user_timeline_response_file) {read_fixture_file('twitter_user_timeline_output.txt')}
    let(:favorites_response_file) {read_fixture_file('twitter_favorites_output.txt')}

    before do
      @user_timeline_request_stub = stub_request(:get, /api\.twitter\.com.*user_timeline/).
        to_return(user_timeline_response_file).then.
        to_return(empty_response_file)

      @favorites_request_stub = stub_request(:get, /api\.twitter\.com.*favorites/).
        to_return(favorites_response_file).then.
        to_return(empty_response_file)
    end

    describe '#fetch_twitter_timeline' do
      it 'should fetch tweets from Twitter' do
        subject.fetch_twitter_timeline
        expect(@user_timeline_request_stub).to have_been_requested.times(2)
      end
    end

    describe '#fetch_twitter_favorites' do
      it 'should fetch tweets from Twitter' do
        subject.fetch_twitter_favorites
        expect(@favorites_request_stub).to have_been_requested.times(2)
      end
    end

    describe '#fetch_from_twitter!' do
      it "should created background jobs to create Links" do
        expect{subject.fetch_from_twitter!}.to change{LinkCreator.jobs.size}.by(2)
      end
    end
  end

  context 'facebook' do
    let(:empty_response_file) {read_fixture_file('facebook_empty_output.txt')}
    let(:links_response_file) {read_fixture_file('facebook_links_output.txt')}
    let(:news_feed_response_file) {read_fixture_file('facebook_news_feed_output.txt')}
    let(:url_likes_response_file) {read_fixture_file('facebook_url_likes_output.txt')}

    before do
      @link_request_stub = stub_request(:get, /.*graph\.facebook\.com\/.*#{Account::FACEBOOK_LINKS_PATH}.*/).
        to_return(links_response_file).then.
        to_return(empty_response_file)

      @news_feed_request_stub = stub_request(:get, /.*graph\.facebook\.com\/.*#{Account::FACEBOOK_NEWS_FEED_PATH}.*/).
        to_return(news_feed_response_file).then.
        to_return(empty_response_file)

      @url_likes_request_stub = stub_request(:get, /.*graph\.facebook\.com\/fql/).
        to_return(url_likes_response_file)
    end

    describe '#fetch_facebook_links' do
      it 'should fetch links from Facebook' do
        subject.fetch_facebook_links
        expect(@link_request_stub).to have_been_requested.times(2)
      end
    end

    describe '#fetch_facebook_news_feed' do
      it 'should fetch news feed objects from Facebook' do
        subject.fetch_facebook_news_feed
        expect(@news_feed_request_stub).to have_been_requested.times(2)
      end
    end

    describe '#fetch_url_likes' do
      it 'should return Array or URLs' do
        expect(subject.fetch_url_likes).to eq ["http://example.com"]
        expect(@url_likes_request_stub).to have_been_requested
      end
    end

    describe '#fetch_from_facebook!' do
      it "should created background jobs to create Links" do
        expect{subject.fetch_from_facebook!}.to change{LinkCreator.jobs.size}.by(2)
      end
    end
  end

  describe '#fetch_links!' do
    let(:fb_empty_response_file) {read_fixture_file('facebook_empty_output.txt')}

    before do
      @fb_link_request_stub = stub_request(:get, /.*graph\.facebook\.com\/.*#{Account::FACEBOOK_LINKS_PATH}.*/).
        to_return(fb_empty_response_file)

      @fb_news_feed_request_stub = stub_request(:get, /.*graph\.facebook\.com\/.*#{Account::FACEBOOK_NEWS_FEED_PATH}.*/).
        to_return(fb_empty_response_file)

      @url_likes_request_stub = stub_request(:get, /.*graph\.facebook\.com\/fql/).
        to_return(fb_empty_response_file)
    end

    it "fetches links and update fetched_at" do
      expect{subject.fetch_links!}.to change{subject.fetched_at}
      expect(@fb_link_request_stub).to have_been_requested
      # expect(@fb_news_feed_request_stub).to have_been_requested
      expect(@url_likes_request_stub).to have_been_requested
    end

    it "does not fetch if Account credentials has expired" do
      subject.credentials["expires_at"] = 1.day.ago.to_i
      subject.save!
      expect(@fb_link_request_stub).to_not have_been_requested
      expect(@url_likes_request_stub).to_not have_been_requested
    end

    it "does not fetch if Account does not have credentials" do
      subject.update!(credentials: nil)
      expect(@fb_link_request_stub).to_not have_been_requested
      expect(@url_likes_request_stub).to_not have_been_requested
    end
  end
end
