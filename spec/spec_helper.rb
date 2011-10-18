# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'rubygems'
require 'spork'
require 'factory_girl_rails'
require 'database_cleaner'

Spork.prefork do

  require "rails/mongoid"
  Spork.trap_class_method(Rails::Mongoid, :load_models)
  require "rails/application"
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)
  require 'rspec/rails'
  require 'capybara/rspec'

  require File.dirname(__FILE__) + "/../config/environment.rb" # <- see this.  Your hackery goes above this.  After this line is too late.
  ENV["RAILS_ENV"] ||= 'test'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    #config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true

    config.include Warden::Test::Helpers, :type => :request

    config.before(:each) do
      DatabaseCleaner.clean
    end

    DatabaseCleaner.strategy = :truncation

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    # config.use_transactional_fixtures = true
  end
end

Spork.each_run do
  FactoryGirl.reload
  DatabaseCleaner.start
end