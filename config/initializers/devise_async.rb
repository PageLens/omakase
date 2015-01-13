Devise::Async.setup do |config|
  config.enabled = true
  config.backend = :sidekiq # Supported options: :resque, :sidekiq, :delayed_job, :queue_classic, :torquebox, :backburner

  config.queue   = :medium
end
