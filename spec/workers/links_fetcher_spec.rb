require 'rails_helper'

describe LinksFetcher do
  let(:account) {create(:account)}

  let(:fb_empty_response_file) {read_fixture_file('facebook_empty_output.txt')}

  before do
    @fb_request_stub = stub_request(:get, /.*graph\.facebook\.com.*/).to_return(fb_empty_response_file)
  end

  it "fetches Links" do
    subject.perform(account.id)
    expect(@fb_request_stub).to have_been_requested.times(2)
  end
end
