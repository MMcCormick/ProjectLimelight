source 'http://rubygems.org'

gem 'bundler'
gem 'rails', '3.2.1'
#gem 'thin'
gem 'jquery-rails'
gem 'mongoid' # MongoDB
gem 'mongoid_slug' # Automatic MongoDB slugs
gem 'mongoid_auto_inc' # Auto incrementing fields in mongoid
gem 'devise' # Authentication
gem 'cells', '3.8.0' # Components
gem 'json' # json processing
#gem 'redcarpet', '1.17.2' # Markdown
gem 'fog' # Cloud support (amazon s3, etc)
gem 'carrierwave' # File uploads
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'koala' # facebook graph api support
gem 'twitter' # twitter api support
#gem 'embedly'
#gem 'heroku'
gem 'resque'
#gem 'resque', :git => 'https://github.com/hone/resque.git', :branch => 'heroku'
gem 'resque-scheduler', '2.0.0.g' # scheduled resque jobs
gem 'resque-loner' # Unique resque jobs
#gem 'hirefireapp' # Heroku web/worker auto scaling hirefireapp.com
gem 'chronic' # Date/Time management
gem 'cancan' # Authorization
gem 'airbrake' # Exception notification
#gem 'rpm_contrib', '2.1.7' # extra instrumentation for the new relic rpm agent
#gem 'newrelic_rpm' # performance / server monitoring
gem 'soulmate' # Redis based autocomplete storage
gem 'dalli' # memcache
gem 'pusher' # pusher publish/subscribe
gem 'ken' # Freebase API for Ruby
gem 'neography' # neo4j graph database
#gem 'active_cache' # conditional caching

group :assets do
  gem 'compass', '0.12.alpha.4'
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', "~> 3.2.1"

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyrhino'

  gem 'uglifier', '>= 1.0.3'
end

group :production do

end

group :development do
  #gem "pry", '0.1'
  #gem 'rspec-cells'
  #gem 'guard-rspec'
  #gem "rails-footnotes"
  #gem "foreman"
  #gem 'ruby-debug'
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  #gem "capybara"
  #gem "factory_girl_rails"
  #gem 'growl'
  #gem 'rb-fsevent'
  #gem "database_cleaner"
  #gem "mongoid-rspec"
  #gem "spork", "> 0.9.0.rc"
  #gem 'guard-spork'
  # gem "cucumber-rails"
  # gem 'mocha'
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'trinidad'
end

gem 'rmagick4j' # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol