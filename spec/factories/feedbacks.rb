# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feedback do
    email "MyString"
    subject "MyString"
    description "MyText"
    note "MyText"
  end
end
