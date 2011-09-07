CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => 'AKIAIQDM2Y5J44SJILXA',       # required
    :aws_secret_access_key  => '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',       # required
    #:region                 => 'us-east-1b'  # optional, defaults to 'us-east-1'
  }
  #config.fog_directory  = 'name_of_directory'                     # required
  #config.fog_host       = 'https://assets.example.com'            # optional, defaults to nil
  #config.fog_public     = false                                   # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end

if Rails.env.development?
  CarrierWave.configure do |config|
    #config.storage = :file
    config.fog_directory  = 'limelight-dev'
    config.fog_host = 'http://duenu7rsiu1ze.cloudfront.net'
  end
end

if Rails.env.test?
  CarrierWave.configure do |config|
    config.fog_directory  = 'limelight_test'
  end
end

if Rails.env.staging?
  CarrierWave.configure do |config|
    config.fog_directory  = 'limelight_staging'
  end
end

if Rails.env.production?
  CarrierWave.configure do |config|
    config.fog_directory  = 'limelight-prod'
  end
end