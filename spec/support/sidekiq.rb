require 'sidekiq/testing'
Sidekiq::Testing.fake!
Sidekiq.logger.level = Logger::WARN
