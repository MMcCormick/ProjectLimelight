class TestJob

  @queue = :fast

  def self.perform()
    users = User.all

    posts = Post.where(:root_type => 'Topic')
    posts.each do |p|
      p.root_type = 'Talk'
      p.root_id = p.id
      p.save
    end

    users.each do |u|
      next if u.id.to_s == User.limelight_user_id

      u.posts_count = 0
      FeedContributeItem.where(:feed_id => u.id).delete
      u.posts.each do |p|
        u.posts_count += 1
        FeedContributeItem.create(p, true)
      end

      activity = FeedContributeItem.where(:feed_id => u.id)
      activity.each do |a|
        a.topic_ids.each do |t|
          u.topic_activity_add(t)
        end
      end

      u.likes_count = 0
      liked_posts = Post.where(:like_ids => u.id).to_a
      FeedLikeItem.where(:feed_id => u.id).delete
      liked_posts.each do |p|
        u.likes_count += 1
        FeedLikeItem.create(u, p, true)
      end
      likes = FeedLikeItem.where(:feed_id => u.id)
      likes.each do |a|
        a.topic_ids.each do |t|
          u.topic_likes_add(t)
        end
      end

      u.topic_activity_recalculate
      u.topic_likes_recalculate

      u.save
    end
  end
end