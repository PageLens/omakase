require 'rails_helper'

describe Page do
  subject {create(:page)}

  it "should truncate attributes" do
    subject.site_name = subject.title = '*' * 2000
    expect(subject.save).to eq true
    expect(subject.title.length).to eq 1000
    expect(subject.site_name.length).to eq 200
  end

  it "should index Links upon save" do
    subject
    link = create(:link, page: subject)
    expect {subject.update(title: 'Test')}.to change{Indexer.jobs.size}.by(1)
  end

  describe '#fetch_needed?' do
    it "should return true if the page has never fetched" do
      subject.fetched_at = nil
      expect(subject).to be_fetch_needed
    end

    it "should return true if the page has not fetched for a long time" do
      subject.fetched_at = CONFIG[:page][:refetch_interval].seconds.ago - 1
      expect(subject).to be_fetch_needed
    end

    it "should return false if the page has been fetched recently" do
      subject.fetched_at = CONFIG[:page][:refetch_interval].seconds.ago + 1
      expect(subject).to_not be_fetch_needed
    end
  end

  describe '#fetch' do
    subject {Page.new(url: 'http://www.example.com')}
    it "fetches information from HTML page" do
      stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('example_output.txt'))
      subject.fetch
      expect(subject.fetched_at).to be
      expect(subject.fetch_error).to be_nil
      expect(subject.html).to be_present
      expect(subject.title).to eq 'Example Domain'
      expect(subject.description).to eq 'This is a test page'
      expect(subject.site_name).to eq 'Example.com'
      expect(subject.content).to include 'Example Domain'
      expect(subject.content_html).to include 'Example Domain'
    end

    it "fetches information from HTML page using OpenGraph tags" do
      stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('example_opengraph_output.txt'))
      subject.fetch
      expect(subject.fetched_at).to be
      expect(subject.fetch_error).to be_nil
      expect(subject.html).to be_present
      expect(subject.title).to eq 'OG Example Domain'
      expect(subject.description).to eq 'This is an OG test page'
      expect(subject.site_name).to eq "OG Example"
      expect(subject.image_url).to eq 'http://www.example.com/logo.png'
      expect(subject.content).to include 'Example Domain'
      expect(subject.content_html).to include 'Example Domain'
    end

    it "should store the error in fetch_error if there is an error fetching the HTML" do
      stub_request(:get, 'http://www.example.com').to_raise(RuntimeError.new('ERROR'))
      subject.fetch
      expect(subject.fetched_at).to be
      expect(subject.fetch_error).to be
      expect(subject.fetch_error[:exception]).to eq 'RuntimeError'
      expect(subject.fetch_error[:message]).to eq 'ERROR'
      expect(subject.fetch_error[:backtrace]).to be
    end

    it "should not fetch the page if the page does not have the text response type" do
      stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('logo.png'))
      subject.fetch
      expect(subject.fetched_at).to be
      expect(subject.content).to be_nil
    end

    it "should not fetch the page if the page has been fetched recently" do
      fetched_at = CONFIG[:page][:refetch_interval].seconds.ago + 1
      subject = build(:page, fetched_at: fetched_at, url: 'http://www.example.com')
      expect {subject.fetch}.to_not change{subject.fetched_at}
    end

    it "should force fetching the page even if the page has been fetched recently" do
      stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('example_output.txt'))
      fetched_at = CONFIG[:page][:refetch_interval].seconds.ago + 1
      subject = build(:page, fetched_at: fetched_at, url: 'http://www.example.com')
      expect {subject.fetch(force: true)}.to change{subject.fetched_at}
    end
  end

  describe '#fetch!' do
    it "saves the Page" do
      subject = Page.new(url: 'http://www.example.com')
      stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('example_output.txt'))
      subject.fetch!
      expect(subject).to be_persisted
    end
  end
end
