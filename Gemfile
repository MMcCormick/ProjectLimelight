source 'http://rubygems.org'

ruby '1.9.3'

gem 'rails', '~> 3.2.13.rc2'
gem 'jquery-rails', '2.0.2'
gem 'rack'
gem 'rack-contrib'
gem 'mongoid', '~> 3.0.1'
gem 'devise', '2.1.2' # Authentication
gem 'yajl-ruby' # json
gem 'aws-s3', :require => 'aws/s3'
gem 'omniauth', '1.1.0'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'koala', '1.5' # facebook graph api support
gem 'twitter' # twitter api support
gem 'tweetstream' # twitter streaming api support
gem 'redis'
gem 'chronic' # Date/Time management
gem 'cancan' # Authorization
gem 'soulmate', '1.0.0', :require => 'soulmate/server' # Redis based autocomplete storage
gem 'dalli' # memcache
gem 'pusher' # pusher publish/subscribe
gem 'neography', '0.0.27' # neo4j graph database
gem 'backbone-on-rails', '0.9.2.1'
gem 'mixpanel' # analytics
gem 'feedzirra'
gem 'ken', :git => 'git://github.com/marbemac/ken.git' # freebase
gem 'mongoid-cached-json', '1.2.3'
gem 'switch_user'
gem 'omnicontacts'
gem 'cloudinary'
#gem 'asset_sync'

gem 'sidekiq' # background jobs
gem 'sidekiq-unique-jobs'
gem 'sinatra' # for sidekiq
gem 'slim'

gem 'bson_ext'
gem 'rmagick', :require => false # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol

gem 'foreman'
gem 'capistrano'

group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'compass-rails'

  gem 'uglifier', '>= 1.0.3'

  gem 'anjlab-bootstrap-rails', '2.0.4.4', :require => 'bootstrap-rails'
end

group :production, :staging do
  gem "rack-timeout"
end

group :development do
  gem "foreman"
  gem 'pry-rails'
  gem 'ruby-prof'
  gem 'thin'
end