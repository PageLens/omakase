Dkim::domain      = 'pagelensmail.com'
Dkim::selector    = 'default'
Dkim::private_key = open("#{Rails.root}/keys/pagelensmail.com.dkim/default.private").read
Dkim::signable_headers = Dkim::DefaultHeaders - %w{Message-ID Resent-Message-ID Date Return-Path Bounces-To}
