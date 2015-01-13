# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :link do
    sequence(:name) {|n| "Link#{n}"}
    note "Note"
    source Link::SOURCES[:web]
    saved_by :me
    user
    page
  end
end
