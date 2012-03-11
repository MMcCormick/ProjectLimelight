# Load AWS::S3 configuration values
S3 = YAML.load_file(File.join(Rails.root, 'config/s3.yml'))[Rails.env]

# Set the AWS::S3 configuration
AWS::S3::Base.establish_connection! S3['connection']