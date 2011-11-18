# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


#puts 'EMPTY THE MONGODB DATABASE'
#Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts 'Creating type of connection'
connection = TopicConnection.find('4eb82a1caaf9060120000081')
unless connection
  connection = TopicConnection.new(
          :name => 'Type Of',
          :pull_from => true,
          :opposite => ''
  )
  connection.user_id = 0
  connection.id = '4eb82a1caaf9060120000081'
  connection.save!
  puts 'Type of connection created'
else
  puts 'Type of connection already in DB'
end

puts 'Creating limelight topic'
topic = Topic.find('4ec69d9fcddc7f9fe80000b8')
unless topic
  topic = Topic.new(
          :name => 'Limelight',
          :aliases => ['Project Limelight', 'projectlimelight', 'limelight project', 'limelightproject'],
          :summary => ''
  )
  topic.id = '4ec69d9fcddc7f9fe80000b8'
  topic.user_id = 0
  topic.save!
  puts 'Limelight topic created'
else
  puts 'Limelight topic already in DB'
end