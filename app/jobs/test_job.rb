class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    Post.all.each do |p|
      unless p.post_media_id && p.post_media
        p.destroy
      end
    end

    User.all.each do |u|
      u.topic_activity_recalculate
      u.topic_likes_recalculate
      u.save
    end

    Topic.all.each do |t|
      users = User.where(:following_topics => t.id)
      t.followers_count = users.length
      t.save
    end

  end
end