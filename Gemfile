require 'rbconfig'
HOST_OS = Config::CONFIG['host_os']
source 'http://rubygems.org'

gem 'rails', '3.1.3'
gem 'unicorn'
#gem 'thin'
gem 'execjs'
gem 'jquery-rails'
gem 'bson_ext'
gem 'mongoid' # MongoDB
gem 'mongoid_slug' # Automatic MongoDB slugs
gem 'mongoid_auto_inc' # Auto incrementing fields in mongoid
gem 'devise' # Authentication
gem 'cells' # Components
gem 'yajl-ruby' # json processing
gem 'redcarpet', '1.17.2' # Markdown
gem 'fog' # Cloud support (amazon s3, etc)
gem 'carrierwave' # File uploads
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'koala' # facebook graph api support
gem 'twitter' # twitter api support
gem 'embedly'
gem 'heroku'
#gem 'resque', :require => 'resque/server'
gem 'resque', :git => 'https://github.com/hone/resque.git', :branch => 'heroku'
gem 'resque-scheduler', '2.0.0.e' # scheduled resque jobs
gem 'resque-loner' # Unique resque jobs
gem 'hirefireapp' # Heroku web/worker auto scaling hirefireapp.com
gem 'chronic' # Date/Time management
gem 'cancan' # Authorization
gem 'airbrake' # Exception notification
gem 'rpm_contrib', '2.1.7' # extra instrumentation for the new relic rpm agent
gem 'newrelic_rpm' # performance / server monitoring
gem 'soulmate' # Redis based autocomplete storage
gem 'dalli' # memcache
gem 'pusher' # pusher publish/subscribe
gem 'ken' # Freebase API for Ruby
gem 'neography' # neo4j graph database

group :assets do
  gem 'compass', '0.12.alpha.0'
  gem 'sass-rails'
  gem 'coffee-rails', "3.1.1"
  gem 'uglifier'
end

group :development do
  gem 'rails-dev-tweaks'
  gem 'heroku_san'
  gem "pry"
  gem 'rspec-cells'
  gem 'guard-rspec'
  gem "rails-footnotes"
  gem "ruby-debug19"
  gem "foreman"
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem "capybara"
  gem "factory_girl_rails"
  gem 'growl'
  gem 'rb-fsevent'
  gem "database_cleaner"
  gem "mongoid-rspec"
  gem "spork", "> 0.9.0.rc"
  gem 'guard-spork'
  # gem "cucumber-rails"
  # gem 'mocha'
end

gem 'rmagick', :require => false # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol
