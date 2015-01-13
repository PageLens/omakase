# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :account do
    user
    provider "facebook"
    sequence(:uid) {|n| "#{n}"}
    info { {"name" => "John Smith", "image" => "http://graph.facebook.com/1231858/picture?type=square", "location" => "Mountain View, California"} }
    credentials { {"token" => "TOKEN", "expires" => "true", "expires_at" => 1.month.from_now.to_i.to_s} }
  end
end
