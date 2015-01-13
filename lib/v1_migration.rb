require 'json'

def to_datetime(field)
  if field.present?
    Time.parse(field)
  else
    nil
  end
end

users_file = File.read('/tmp/users.json').gsub(/,\n\]$/, ']')
JSON.parse(users_file).each do |u|
  u = u.with_indifferent_access
  User.create!(id: u[:id], email: u[:email], encrypted_password: u[:encrypted_password], sign_in_count: u[:sign_in_count], confirmation_token: u[:confirmation_token], confirmed_at: to_datetime(u[:confirmed_at]), confirmation_sent_at: to_datetime(u[:confirmation_sent_at]), unconfirmed_email: u[:unconfirmed_email], created_at: to_datetime(u[:created_at]), name: u[:name], username: u[:username], time_zone: u[:time_zone], image_url: u[:image_url], skip_password: true)
end

accounts_file = File.read('/tmp/accounts.json').gsub(/,\n\]$/, ']')
JSON.parse(accounts_file).each do |a|
  a = a.with_indifferent_access
  Account.create!(id: a[:id], user_id: a[:user_id], provider: a[:provider], uid: a[:uid], created_at: to_datetime(a[:created_at]))
end

bookmarks_file = File.read('/tmp/bookmarks.json').gsub(/,\n\]$/, ']')
JSON.parse(bookmarks_file).each do |b|
  b = b.with_indifferent_access
  LinkCreator.perform_async({
    name: b[:name],
    keywords: b[:keywords].present? ? b[:keywords] : nil,
    folders: b[:keywords].present? ? b[:keywords] : nil,
    note: b[:note],
    source: b[:source],
    source_id: b[:source_id],
    saved_at: to_datetime(b[:bookmarked_at]),
    user_id: b[:user_id],
    url: b[:url],
    image_url: b[:image_url],
    title: b[:title],
    site_name: b[:site_name],
    description: b[:description]
  })
end
