source 'http://rubygems.org'

gem 'bundler'
gem 'rails', '3.2.3'
gem 'jquery-rails'
gem 'rack'
gem 'rack-contrib'
gem 'mongoid' # MongoDB
gem 'mongoid_slug' # Automatic MongoDB slugs
gem 'mongoid_auto_inc' # Auto incrementing fields in mongoid
gem 'devise' # Authentication
gem 'yajl-ruby' # json
gem 'aws-s3', :require => 'aws/s3'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'koala' # facebook graph api support
gem 'twitter' # twitter api support
gem 'resque', '1.20.0'#, :git => 'https://github.com/hone/resque.git', :branch => 'heroku'
gem 'resque-scheduler', '2.0.0.h' # scheduled resque jobs
gem 'resque-loner' # Unique resque jobs
gem 'chronic' # Date/Time management
gem 'cancan' # Authorization
gem 'airbrake' # Exception notification
gem 'soulmate', '0.1.2', :require => 'soulmate/server' # Redis based autocomplete storage
gem 'dalli' # memcache
gem 'pusher' # pusher publish/subscribe
gem 'ken' # Freebase API for Ruby
gem 'neography' # neo4j graph database
gem 'backbone-on-rails'
gem 'asset_sync' # can maybe move this to assets group?
gem 'datasift' # streaming api access (twitter, facebook, youtube, etc)

group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'compass-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  #gem 'therubyrhino'

  gem 'closure-compiler'

  gem 'anjlab-bootstrap-rails', '>= 2.0', :require => 'bootstrap-rails'
end

group :production do
  gem 'thin'
end

group :development do
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  #gem 'ruby-prof'
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

platforms :ruby do
  gem 'bson_ext'
  gem 'rmagick', :require => false # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol
  gem 'hirefireapp' # Heroku web/worker auto scaling hirefireapp.com
  gem 'heroku'
  gem 'rpm_contrib', '2.1.7' # extra instrumentation for the new relic rpm agent
  gem 'newrelic_rpm' # performance / server monitoring

  group :development do
    gem "foreman"
  end
end

platforms :jruby do
  #gem 'jruby-openssl'
  #gem 'trinidad'
  #gem 'bson'
  #gem 'rmagick4j' # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol
end

