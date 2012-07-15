class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    PostMedia.each do |pm|
      pm.shares = []
      pm.ll_score = 0
      pm.comments = []
      pm.comment_count = 0
      pm.save
    end

    Post.all.each do |p|
      media = p.post_media

      unless media
        p.destroy
        next
      end

      media.add_share(p.user_id, p.content, p.topic_mention_ids, [], {:limelight => nil})

      p.comments.each do |c|
        media.add_comment(c.user_id, c.content)
      end
      media.save
    end

    PostMedia.each do |pm|
      pm.shares.each do |s|
        FeedUserItem.push_post_through_users(pm, s.user, false, true)
        FeedUserItem.push_post_through_topics(pm)
      end
    end

  end
end