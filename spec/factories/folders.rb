# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :folder do
    sequence(:name) {|n| "Folder #{n}"}
    user
  end
end
