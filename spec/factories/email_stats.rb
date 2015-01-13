# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :email_stat do
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
