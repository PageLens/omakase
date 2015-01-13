# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :folder_invitation do
    folder
    user { folder.user }
    email "recipient@example.com"
    message "Join my folder"
  end
end
