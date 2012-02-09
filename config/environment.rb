# Load the rails application
require File.expand_path('../application', __FILE__)

# Assign environment variables
variables = YAML.load_file("#{Rails.root}/config/environment.yml")[Rails.env]
variables.each { |key,val| ENV[key.to_s] = val.to_s } if variables

# Initialize the rails application
ProjectLimelight::Application.initialize!

DOMAIN_NAMES = {"staging" => "staging.projectlimelight.com", "development" => "localhost:3000", "production" =>  "www.projectlimelight.com", "test" => "localhost:3000"}