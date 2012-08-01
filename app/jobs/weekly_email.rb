class WeeklyEmail
  include Resque::Plugins::UniqueJob

  @queue = :slow_limelight

  def self.perform
    talks = FeedTopicItem.where(:root_type => 'Talk').desc(:p).limit(3).to_a
    links = FeedTopicItem.where(:root_type => 'Link').desc(:p).limit(3).to_a
    pictures = FeedTopicItem.where(:root_type => 'Picture').desc(:p).limit(3).to_a
    videos = FeedTopicItem.where(:root_type => 'Video').desc(:p).limit(3).to_a

    obj_ids = []
    [talks, links, pictures, videos].each do |objs|
      obj_ids = obj_ids + objs.map{ |obj| obj.root_id }
    end
    objects = Post.where(:_id.in => obj_ids)

    pop_talks = objects.select{|o| o._type == 'Talk'}
    pop_links = objects.select{|o| o._type == 'Link'}
    pop_pics = objects.select{|o| o._type == 'Picture'}
    pop_vids = objects.select{|o| o._type == 'Video'}

    User.all.each do |user|
      NewsletterMailer.weekly_email(user, pop_talks, pop_links, pop_pics, pop_vids).deliver if user.weekly_email
    end
  end
end