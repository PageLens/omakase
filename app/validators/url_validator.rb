require 'uri'

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      uri = URI::parse(value)
      r = uri.kind_of?(URI::HTTP)
    rescue URI::InvalidURIError => e
      r = false
    end
    record.errors[attribute] << (options[:message] || "is invalid") unless r
  end
end
