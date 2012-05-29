source 'http://rubygems.org'

#ruby '1.9.3'

gem 'bundler'
gem 'thin'
gem 'rails', '3.2.3'
gem 'jquery-rails'
gem 'rack'
gem 'rack-contrib'
gem 'mongoid', '3.0.0.rc', :require => 'mongoid' # MongoDB
gem 'devise' # Authentication
gem 'yajl-ruby' # json
gem 'aws-s3', :require => 'aws/s3'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'koala', '1.4.1' # facebook graph api support
gem 'twitter' # twitter api support
gem 'resque' #'1.20.0'#, :git => 'https://github.com/hone/resque.git', :branch => 'heroku'
gem 'resque-scheduler', '2.0.0.h', :require => 'resque_scheduler' # scheduled resque jobs
gem 'resque-loner' # Unique resque jobs
gem 'resque_mailer'
gem 'chronic' # Date/Time management
gem 'cancan' # Authorization
gem 'airbrake' # Exception notification
gem 'soulmate', '0.1.2', :require => 'soulmate/server' # Redis based autocomplete storage
gem 'dalli' # memcache
gem 'pusher' # pusher publish/subscribe
gem 'neography' # neo4j graph database
gem 'backbone-on-rails'
gem 'mixpanel' # analytics
gem 'feedzirra'
gem 'ken' # freebase
gem 'mongoid-cached-json', :git => 'git://github.com/marbemac/mongoid-cached-json.git'
#gem 'mongoid_collection_snapshot'


group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'compass-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  #gem 'therubyrhino'

  gem 'closure-compiler'

  gem 'asset_sync'

  gem 'anjlab-bootstrap-rails', '>= 2.0', :require => 'bootstrap-rails'
end

group :production do

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
  #gem 'hirefireapp' # Heroku web/worker auto scaling hirefireapp.com
  gem 'heroku'
  gem 'newrelic_rpm'
  #gem 'rpm_contrib', '2.1.11' # extra instrumentation for the new relic rpm agent
  #gem 'newrelic-redis', '1.3.2' # new relic redis instrumentation
  #gem 'newrelic-faraday'

  group :development do
    gem "foreman"
    gem 'pry-rails'
  end
end

platforms :jruby do
  #gem 'jruby-openssl'
  #gem 'trinidad'
  #gem 'bson'
  #gem 'rmagick4j' # Image manipulation (put rmagick at the bottom because it's a little bitch about everything) #McM: lol
end

