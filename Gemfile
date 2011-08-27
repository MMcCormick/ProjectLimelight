source 'http://rubygems.org'
gem 'rails', '3.1.0.rc6'
gem 'execjs'
gem 'jquery-rails'
gem "bson_ext"
gem "mongoid"
gem "devise"
gem "frontend-helpers"
gem "cells"
gem "rspec-cells"
group :assets do
  gem 'sass-rails', "  ~> 3.1.0.rc"
  gem 'compass', :git => 'git://github.com/chriseppstein/compass.git', :branch => 'rails31'
  gem 'coffee-rails', "~> 3.1.0.rc"
  gem 'uglifier'
end
group :production do
  gem 'therubyracer'
end
gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]
group :development do
  gem "rails-footnotes"
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
