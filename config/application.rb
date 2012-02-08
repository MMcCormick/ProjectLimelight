require File.expand_path('../boot', __FILE__)

## monkey patch for jruby 1.6.5.1 'fiber' bug (torquebox requires 1.6.5.1) Feb 7, 2012
#if defined?(JRUBY_VERSION) && JRUBY_VERSION == "1.6.5.1"
#  require 'jruby'
#  JRuby.runtime.getLoadService.removeBuiltinLibrary("fiber.rb")
#  JRuby.runtime.addLazyBuiltin("fiber.rb", "fiber", "org.jruby.ext.fiber.FiberExtLibrary")
#
#  class Fiber
#    def alive?
#      JRuby.reference(self).state != org.jruby.ext.fiber.ThreadFiberState::FINISHED
#    end
#  end
#end

# Pick the frameworks you want:
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "compass"
require 'coffee_script'
require "sass-rails"
require 'uri'
require 'open-uri'
require 'chronic'
require 'pusher'
require 'ken' # Freebase API for Ruby

gem PLATFORM == 'java' ? 'rmagick4j' : 'rmagick'
require 'RMagick'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module ProjectLimelight
  class Application < Rails::Application

    # don't generate RSpec tests for views and helpers
    config.generators do |g|
      g.view_specs false
      g.helper_specs false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '.1'

    config.assets.initialize_on_precompile = false
  end
end