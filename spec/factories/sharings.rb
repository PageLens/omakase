# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sharing do
    folder
    user
    creator { folder.user }
  end
end
