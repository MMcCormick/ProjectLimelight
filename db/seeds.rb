# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


#puts 'EMPTY THE MONGODB DATABASE'
#Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'Creating marc'
marc = User.find(User.marc_id)
unless marc
  marc = User.new(
          :username => 'Marc',
          :first_name => 'Marc',
          :last_name => 'MacLeod',
          :email => 'marbemac@gmail.com',
          :password => '87yot4',
          :password_confirmation => '87yot4'
  )
  marc.grant_role('admin')
  marc.id = User.marc_id
  marc.save!
  puts 'marc created'
else
  puts 'marc already in DB'
end

puts 'Creating matt'
matt = User.find(User.matt_id)
unless matt
  matt = User.new(
          :username => 'Matt',
          :first_name => 'Matt',
          :last_name => 'McCormick',
          :email => 'matt.c.mccormick@gmail.com',
          :password => '87yot4',
          :password_confirmation => '87yot4'
  )
  matt.grant_role('admin')
  matt.id = User.matt_id
  matt.save!
  puts 'matt created'
else
  puts 'matt already in DB'
end

puts 'Creating type of connection'
connection = TopicConnection.find(Topic.type_of_id)
unless connection
  connection = TopicConnection.new(
          :name => 'Type Of',
          :reverse_name => 'Instance',
          :pull_from => false,
          :reverse_pull_from => true
  )
  connection.user_id = marc.id
  connection.id = Topic.type_of_id
  connection.save!
  puts 'Type of connection created'
else
  puts 'Type of connection already in DB'
end

puts 'Creating limelight topic'
topic = Topic.find(Topic.limelight_id)
unless topic
  topic = Topic.new(
          :name => 'Limelight',
          :summary => ''
  )
  ['limelight', 'Project Limelight', 'projectlimelight', 'limelight project', 'limelightproject'].each do |name|
    topic.add_alias name
  end
  topic.id = Topic.limelight_id
  topic.user_id = marc.id
  topic.save!
  puts 'Limelight topic created'
else
  puts 'Limelight topic already in DB'
end

puts 'Creating limelight feedback topic'
topic = Topic.find(Topic.limelight_feedback_id)
unless topic
  topic = Topic.new(
          :name => 'Limelight Feedback',
          :summary => ''
  )
  ['Limelight Feedback', 'limelightfeedback', 'project limelight feedback'].each do |name|
    topic.add_alias name
  end
  topic.id = Topic.limelight_feedback_id
  topic.user_id = marc.id
  topic.save!
  puts 'Limelight feedback topic created'
else
  puts 'Limelight feedback topic already in DB'
end