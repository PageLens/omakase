class LinksFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :medium, retry: 3, backtrace: true

  # Public: Fetches the Links for an Account.
  #
  # account_id: ID of User Account.
  #
  def perform(account_id, options={})
    Account.find(account_id).fetch_links!(options.with_indifferent_access)
  end
end

