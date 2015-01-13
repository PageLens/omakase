Dkim::domain      = 'pagelensmail.com'
Dkim::selector    = 'default'
Dkim::private_key = case Rails.env
when "development", "test" then open("#{Rails.root}/keys/pagelensmail.com.dkim/default.private").read
else open("/home/deploy/keys/pagelensmail.com.dkim/default.private").read
end
Dkim::signable_headers = Dkim::DefaultHeaders - %w{Message-ID Resent-Message-ID Date Return-Path Bounces-To}
