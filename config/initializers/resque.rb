require 'resque_scheduler'
require 'resque/failure/multiple'
require 'resque/failure/airbrake'
require 'resque/failure/redis'

if ENV["REDISTOGO_URL"]
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
elsif Rails.env.development?
  Resque.redis = 'localhost:6379'
end

Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }

Resque::Failure::Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']
  config.secure = true
end
Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
Resque::Failure.backend = Resque::Failure::Multiple

#Resque::Scheduler.dynamic = true
#Resque.schedule = YAML.load_file(File.join('config/resque_schedule.yml'))