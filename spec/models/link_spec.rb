require 'rails_helper'

RSpec.describe Link, :type => :model do
  subject {create(:link)}
  let(:user_id) {1}
  let(:folder_id) {1}

  it "should create background job to update Link index when Link is created" do
    expect{create(:link)}.to change{Indexer.jobs.size}.by(1)
  end

  it "should create background job to update Link index when Link is updated" do
    subject
    expect{subject.update(name: 'Test')}.to change{Indexer.jobs.size}.by(1)
  end

  it "should create background job to delete Link index when Link is destroyed" do
    subject
    expect{subject.destroy}.to change{Indexer.jobs.size}.by(1)
  end

  it "should return URL from the Page" do
    expect(subject.url).to eq subject.page.url
  end

  it "append http protocol to url" do
    subject = build(:link)
    subject.url = 'www.example.com'
    expect(subject.url).to eq 'http://www.example.com'
    subject.url = 'https://www.example.com'
    expect(subject.url).to eq 'https://www.example.com'
  end

  it "strip white spaces no url" do
    subject = build(:link)
    subject.url = ' http://www.example.com'
    expect(subject.url).to eq 'http://www.example.com'
  end

  it "should return URL from accessor if it does not have a Page" do
    subject = Link.new(url: 'http://www.example.com')
    expect(subject.url).to eq 'http://www.example.com'
  end

  it "should create a Page when creating a Link" do
    expect{Link.create(url: 'http://www.example.com', user_id: user_id, source: Link::SOURCES[:web])}.to change{Page.count}.by(1)
  end

  it "should not create a Page if there exists a Page with the URL" do
    page = create(:page)
    expect{Link.create(url: page.url, user_id: user_id, source: Link::SOURCES[:web])}.to_not change{Page.count}
  end

  it "should not allow a Link to be created with a proper URL or a Page" do
    expect(Link.new(user_id: user_id, source: Link::SOURCES[:web]).save).to eq false
  end

  it "should not allow Link to move to a Folder that the creator cannot access" do
    folder = create(:folder, user: create(:user))
    subject.folder = folder
    expect(subject).to_not be_valid
  end

  describe '#name' do
    it "returns the name of the Link if it is set" do
      subject.update(name: 'Test')
      expect(subject.name).to eq 'Test'
    end

    it "returns the title from the Page if the name is not set" do
      subject.update(name: nil)
      expect(subject.name).to eq subject.page.title
    end
  end

  describe '#tags' do
    it 'sets tags' do
      subject.tags = 'tag1'
      expect(subject.keywords).to eq ['tag1']
      subject.tags = 'tag1,,'
      expect(subject.keywords).to eq ['tag1']
      subject.tags = 'tag1, tag2,tag3'
      expect(subject.keywords).to eq ['tag1', 'tag2', 'tag3']
      subject.tags = ''
      expect(subject.keywords).to be_nil
      subject.tags = nil
      expect(subject.keywords).to be_nil
    end

    it 'gets tags' do
      subject.keywords = nil
      expect(subject.tags).to be_nil
      subject.keywords = ['tag1', 'tag2']
      expect(subject.tags).to eq 'tag1, tag2'
    end
  end

  describe '.for_user' do
    let(:user) {create(:user)}

    it "should returns Links created by User" do
      link = create(:link, user: user)
      expect(Link.for_user(user).to_a).to include link
    end

    it "should returns Links shared to User" do
      another_user = create(:user)
      folder = create(:folder, user: another_user)
      link = create(:link, user: another_user, folder: folder)
      sharing = create(:sharing, folder: folder, creator: another_user, user: user)
      expect(Link.for_user(user).to_a).to include link
    end

    it "should not returns Links that is not created by User and not shared to the User" do
      another_user = create(:user)
      folder = create(:folder, user: another_user)
      link = create(:link, user: another_user, folder: folder)
      expect(Link.for_user(user).to_a).to_not include link
      expect(Link.for_user(user, folder_id: folder.id).to_a).to_not include link
    end
  end

  describe '.search' do
    it "should perform search" do
      expect_any_instance_of(Elasticsearch::Model::Proxy::ClassMethodsProxy).to receive(:search)
      Link.search(query: 'Query', user_id: user_id)
    end
  end

  describe '.search_for_user' do
    it "should perform search with the User ID" do
      user = create(:user)
      response = double
      expect(Link).to receive(:search).with(hash_including(user_id: user.id)).and_return(response)
      Link.search_for_user(user, query: 'Query')
    end

    it "should perform search with the shared Folders" do
      user = create(:user)
      folder = create(:folder)
      sharing = create(:sharing, user_id: user.id, folder_id: folder.id, creator: folder.user)
      response = double
      expect(Link).to receive(:search).with(hash_including(folder_ids: [folder.id])).and_return(response)
      Link.search_for_user(user, query: 'Query')
    end
  end

  describe '.search_definition' do
    it "should contain the options[:query] if it is present" do
      sd = Link.search_definition(query: 'Query', user_id: user_id, decay: false)
      expect(sd[:query][:bool][:must].size).to eq 1
      expect(sd[:query][:bool][:must][0][:multi_match]).to be_present
      expect(sd[:query][:bool][:must][0][:multi_match][:query]).to eq 'Query'
    end

    it "should include the User ID" do
      sd = Link.search_definition(user_id: 1)
      expect(sd[:query][:bool][:should].size).to eq 1
      expect(sd[:query][:bool][:should][0][:term][:user_id]).to eq 1
      expect(sd[:query][:bool][:minimum_should_match]).to eq 1
    end

    it "should include the Folder IDs" do
      sd = Link.search_definition(folder_ids: [folder_id])
      expect(sd[:query][:bool][:should].size).to eq 1
      expect(sd[:query][:bool][:should][0][:terms][:folder_id]).to eq [folder_id]
      expect(sd[:query][:bool][:minimum_should_match]).to eq 1
    end

    it "should include suggest if options[:query] is present" do
      sd = Link.search_definition(user_id: user_id)
      expect(sd[:suggest]).to be_blank
    end

    it "should not include suggest if options[:query] is blank" do
      sd = Link.search_definition(query: 'Query', user_id: user_id)
      expect(sd[:suggest]).to be_present
    end

    it "should return sort in saved_at if options[:sort] is blank" do
      sd = Link.search_definition(user_id: user_id)
      expect(sd[:sort].keys.first).to eq :saved_at
    end

    it "should return sort in options[:sort] if it is present" do
      sd = Link.search_definition(user_id: user_id, sort: 'title')
      expect(sd[:sort].keys.first).to eq 'title'
    end

    it "should include folder_id filter if options[:folder_id] is present" do
      sd = Link.search_definition(user_id: 1, folder_id: folder_id)
      [sd[:filter], sd[:facets][:source][:facet_filter], sd[:facets][:site_name][:facet_filter]].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:term][:folder_id]).to eq folder_id
      end
    end

    it "should include saved_at filter if options[:since] is present" do
      since = 1.month.ago.midnight
      sd = Link.search_definition(user_id: 1, since: since)
      [
        sd[:filter],
        sd[:facets][:folder_id][:facet_filter],
        sd[:facets][:keywords][:facet_filter],
        sd[:facets][:source][:facet_filter],
        sd[:facets][:keywords][:facet_filter],
        sd[:facets][:saved_by][:facet_filter]
      ].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:range][:saved_at][:gte]).to eq since
      end
    end

    it "should include site_name filter if options[:site_name] is present" do
      site_name = 'PageLens'
      sd = Link.search_definition(user_id: 1, site_name: site_name)
      [
        sd[:filter],
        sd[:facets][:folder_id][:facet_filter],
        sd[:facets][:keywords][:facet_filter],
        sd[:facets][:source][:facet_filter],
        sd[:facets][:saved_by][:facet_filter]
      ].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:term]['page.site_name']).to eq site_name
      end
    end

    it "should include source filter if options[:source] is present" do
      source = 'facebook'
      sd = Link.search_definition(user_id: 1, source: source)
      [
        sd[:filter],
        sd[:facets][:folder_id][:facet_filter],
        sd[:facets][:keywords][:facet_filter],
        sd[:facets][:site_name][:facet_filter],
        sd[:facets][:saved_by][:facet_filter]
      ].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:term][:source]).to eq source
      end
    end

    it "should include saved_by filter if options[:saved_by] is present" do
      saved_by = 'me'
      sd = Link.search_definition(user_id: 1, saved_by: saved_by)
      [
        sd[:filter],
        sd[:facets][:folder_id][:facet_filter],
        sd[:facets][:keywords][:facet_filter],
        sd[:facets][:site_name][:facet_filter],
        sd[:facets][:source][:facet_filter]
      ].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:term][:saved_by]).to eq saved_by
      end
    end

    it "should include keywords filter if options[:keywords] is present" do
      keywords = 'keywords'
      sd = Link.search_definition(user_id: 1, keywords: keywords)
      [
        sd[:filter],
        sd[:facets][:folder_id][:facet_filter],
        sd[:facets][:site_name][:facet_filter],
        sd[:facets][:source][:facet_filter],
        sd[:facets][:saved_by][:facet_filter]
      ].each do |field|
        expect(field[:and].size).to eq 1
        expect(field[:and][0][:term][:keywords]).to eq keywords
      end
    end
  end
end
