class TestingController < ApplicationController

  def test

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
            topic.save
            total += 1
          end
        end
      end
    end
    foo = 'bar'
  end

end