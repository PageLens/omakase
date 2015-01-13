# Indexer class for <http://sidekiq.org>
#
# To remove all indices: curl -XDELETE 'http://localhost:9200/_all'
#
class Indexer
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false, backtrace: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Client.new host: (ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'), logger: Logger

  # Public: Index a record.
  #
  # operation - :index, :update, or :delete.
  # klass - Name of the Class.
  # record - Record ID.
  # options - Index options.
  #
  def perform(operation, klass, record_id, options={})
    logger.debug [operation, "#{klass}##{record_id} #{options.inspect}"]

    case operation.to_s
      when /index|update/
        record = klass.constantize.find(record_id)
        record.__elasticsearch__.client = Client
        record.__elasticsearch__.__send__ "#{operation}_document"
      when /delete/
        Client.delete index: klass.constantize.index_name, type: klass.constantize.document_type, id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
