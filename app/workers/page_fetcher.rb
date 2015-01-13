class PageFetcher
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3, backtrace: true

  # Public: Fetches the Page content and save it.
  def perform(page_id, options={})
    Page.find(page_id).fetch!(options.with_indifferent_access)
  end
end
