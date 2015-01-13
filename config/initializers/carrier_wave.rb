CarrierWave.configure do |config|
  # config.fog_credentials = {
  #   :provider                         => 'Google',
  #   :google_storage_access_key_id     => Rails.application.secrets.google_storage['access_key'],
  #   :google_storage_secret_access_key => Rails.application.secrets.google_storage['secret']
  # }
  # config.fog_directory = 'bookmark_files'
end
if Rails.env.test? or Rails.env.cucumber?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
end
