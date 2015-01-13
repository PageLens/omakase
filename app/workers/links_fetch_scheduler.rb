class LinksFetchScheduler
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  sidekiq_options queue: :low, retry: 3, backtrace: true

  recurrence(backfill: true) {hourly}

  def perform
    account_ids = Account.where("credentials IS NOT NULL AND (fetched_at IS NULL OR fetched_at < :time_ago)", time_ago: 2.hours.ago).pluck(:id)
    account_ids.each {|aid| LinksFetcher.perform_async(aid)}
  end
end
