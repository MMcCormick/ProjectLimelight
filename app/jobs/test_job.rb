class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    Post.all.each do |p|
      if p.user_id == User.limelight_user_id
        p.destroy
      end
    end

    PostMedia.all.each do |pm|
      post = Post.where(:post_media_id => pm.id).first
      unless post
        pm.destroy
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