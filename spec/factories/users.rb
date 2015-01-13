# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:username)             {|n| "user#{n}"}
    sequence(:email)                {|n| "user#{n}@example.com"}
    sequence(:name)                 {|n| "User#{n}"}
    password                        "password"
    password_confirmation           {password}
    confirmed_at                    {1.day.ago}
  end
end
