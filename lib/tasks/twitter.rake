namespace :twitter do

  task :all => [:insert_daily_trends, :insert_hourly_trends]

  desc "Inject daily twitter trends."
  task :insert_daily_trends => :environment do
    total = 0
    5.times do |past|
      print "Fetching twitter trends for: #{Chronic.parse("#{past} weeks ago")}\n"
      days = Twitter.trends_weekly(Chronic.parse("#{past} weeks ago"), {:exclude => 'hashtags'})
      days.each do |day, trends|
        trends.each do |trend|
          found = Topic.where(:slug => trend[:name].to_url).first
          unless found
            topic = Topic.create(
                    :name => trend[:name]
            )
            topic.user_id = [User.marc_id, User.matt_id].sample
            topic.save
            total += 1
          end
        end
      end
    end

    print "Loading #{total} twitter topics into limelight.\n"
    end

  desc "Inject hourly twitter trends."
  task :insert_hourly_trends => :environment do
    total = 0
    10.times do |past|
      print "Fetching twitter trends for: #{Chronic.parse("#{past} days ago")}\n"
      days = Twitter.trends_daily(Chronic.parse("#{past} days ago"), {:exclude => 'hashtags'})
      days.each do |day, trends|
        trends.each do |trend|
          found = Topic.where(:slug => trend[:name].to_url).first
          unless found
            topic = Topic.create(
                    :name => trend[:name]
            )
            topic.user_id = [User.marc_id, User.matt_id].sample
            topic.save
            total += 1
          end
        end
      end
    end

    print "Loading #{total} twitter topics into limelight.\n"
  end
end