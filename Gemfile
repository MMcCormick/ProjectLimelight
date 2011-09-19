source 'http://rubygems.org'
gem 'rails', '3.1.0'
gem 'execjs'
gem 'jquery-rails'
gem 'bson_ext'
gem 'mongoid' # MongoDB
gem 'mongoid_slug' # Automatic MongoDB slugs
gem 'mongoid_auto_inc' # Auto incrementing fields in mongoid
gem 'devise' # Authentication
gem 'frontend-helpers'
gem 'cells' # Components
gem 'rspec-cells'
gem 'redcarpet' # Markdown
gem 'fog' # Cloud support (amazon s3, etc)
gem 'rmagick' # Image manipulation
gem 'carrierwave' # File uploads
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
#gem 'typhoeus', :path => 'C:\RailsInstaller\Ruby1.9.2\lib\ruby\gems\1.9.1\gems\typhoeus-0.1.31'
gem 'embedly'
gem 'resque', :require => 'resque/server' # Background jobs

group :assets do
  gem 'compass', :git => 'git://github.com/chriseppstein/compass.git', :branch => 'rails31'
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

group :production do
  #gem 'therubyracer'
end

gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]

group :development do
  gem "rails-footnotes"
  gem "pry"
  gem "ruby-debug19"
  gem "foreman"
end

group :test do
  gem "database_cleaner", ">= 0.6.7"
  gem "mongoid-rspec", ">= 1.4.4"
  gem "factory_girl_rails", ">= 1.1.0"
  gem "cucumber-rails", ">= 1.0.2"
  gem "capybara", ">= 1.0.0"
  gem "launchy", ">= 2.0.5"
  gem "ZenTest"
  gem "autotest-rails-pure"
  gem "autotest-growl"
  gem "autotest-fsevent"
  gem "spork"
  gem "guard"
  gem "guard-spork"
end
