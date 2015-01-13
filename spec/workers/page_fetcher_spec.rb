require 'rails_helper'

describe PageFetcher do
  let(:page) {create(:page, fetched_at: nil, content: nil, url: 'http://www.example.com')}

  it "fetches the Page content" do
    stub_request(:get, 'http://www.example.com').to_return(read_fixture_file('example_output.txt'))
    subject.perform(page.id)
    page.reload
    expect(page.fetched_at).to be
    expect(page.fetch_error).to be_nil
    expect(page.content).to include 'Example Domain'
  end
end
