source 'http://rubygems.org'

ruby '1.9.3'

gem 'rails', '~> 3.2.13.rc2'
gem 'jquery-rails', '~> 2.0.2'
gem 'rack'
gem 'rack-contrib'
gem 'mongoid', '~> 3.0.1'
gem 'devise' # Authentication
gem 'yajl-ruby' # json
gem 'aws-s3', :require => 'aws/s3'
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
gem 'mongoid-cached-json'
gem 'switch_user'
gem 'omnicontacts'
gem 'cloudinary'

gem 'sidekiq' # background jobs
gem 'sidekiq-unique-jobs'
gem 'sinatra' # for sidekiq
gem 'slim'
#gem 'resque', '1.21.0' #, :git => 'https://github.com/hone/resque.git', :branch => 'heroku'
#gem 'resque-scheduler', '2.0.0.h', :require => 'resque_scheduler' # scheduled resque jobs
#gem 'resque-loner' # Unique resque jobs
#gem 'resque_mailer'

gem 'bson_ext'
gem 'rmagick', :require => false # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol

gem 'foreman'

group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'compass-rails'

  gem 'closure-compiler'

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
  gem 'capistrano'
  gem 'rvm-capistrano'
end