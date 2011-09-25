require 'rbconfig'
HOST_OS = Config::CONFIG['host_os']
source 'http://rubygems.org'

gem 'rails', '3.1.0'
gem 'execjs'
gem 'jquery-rails'
gem 'mongoid' # MongoDB
gem 'mongoid_slug' # Automatic MongoDB slugs
gem 'mongoid_auto_inc' # Auto incrementing fields in mongoid
gem 'devise' # Authentication
gem 'frontend-helpers'
gem 'cells' # Components
gem 'rspec-cells'
gem 'yajl-ruby' # json processing
gem 'redcarpet' # Markdown
gem 'fog' # Cloud support (amazon s3, etc)
gem 'rmagick' # Image manipulation
gem 'carrierwave' # File uploads
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'embedly'
gem 'resque', :require => 'resque/server' # Background jobs
gem 'chronic' # Date/Time management

group :assets do
  gem 'compass', '~> 0.12.alpha'
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]

group :development do
  gem "rails-footnotes"
  gem "pry"
  gem "ruby-debug19"
  gem "foreman"
  gem "guard"
  gem "guard-bundler", ">= 0.1.3"
  gem "guard-rails", ">= 0.0.3"
  gem "guard-livereload"
  gem "guard-rspec"
  gem "guard-cucumber"
  gem "spork"
  gem "guard-spork"
  gem 'bson_ext'

  case HOST_OS
    when /darwin/i
      gem 'rb-fsevent'
      gem 'growl'
    when /linux/i
      gem 'libnotify'
      gem 'rb-inotify'
    when /mswin|windows/i
      gem 'rb-fchange'
      gem 'win32console'
      gem 'rb-notifu'
  end

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
end

if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end
