Sidekiq.configure_client do |config|
  if ENV["REDIS_URL"]
    config.redis = { :url => ENV["REDIS_URL"], :size => 1 }
  else
    config.redis = { :url => 'redis://localhost:6379', :size => 1 }
  end
end