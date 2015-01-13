# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page do
    sequence(:url) {|n| "http://www.example.com/#{n}"}
    image_url "http://www.example.com/image.png"
    sequence(:title) {|n| "Title #{n}"}
    site_name "Example"
    description "Description"
    html "<html><body><div>Test</div></body></html>"
    content "Test"
    content_html "<div>Test</div>"
    content_type "html"
    fetch_error nil
    fetched_at {1.day.ago}
  end
end
