require 'rails_helper'

describe LinksFetchScheduler do
  it "creates background jobs for Accounts that has credentials and has not fetched for a while" do
    account1 = create(:account, fetched_at: nil)
    account2 = create(:account, credentials: nil)
    account3 = create(:account, fetched_at: 1.minute.ago)
    account4 = create(:account, fetched_at: 1.day.ago)
    LinksFetcher.jobs.clear
    expect{subject.perform}.to change(LinksFetcher.jobs, :size).by(2)
    args = LinksFetcher.jobs.map{|j| j['args'].first}
    expect(args).to include account1.id
    expect(args).to include account4.id
  end
end
