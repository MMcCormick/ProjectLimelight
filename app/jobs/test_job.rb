class TestJob

  @queue = :fast

  def self.perform()
    Post.all.destroy
    FeedUserItem.all.delete
    FeedTopicItem.all.delete
    FeedContributeItem.all.delete
    FeedLikeItem.all.delete
    Comment.all.delete
    PopularityAction.all.delete

    User.update_all(:score => 0.0, :likes_count => 0, :unread_notification_count => 0, :clout => 1, )

    @destroyed = 0
    @updated = 0
    topics = Topic.all
    topics.each do |t|
      primary_for = Topic.where(:primary_type_id => t.id)
      if primary_for.length == 0 && t.followers_count == 0 && !t.fb_page_id && !t.is_category && !t.primary_type_id
        t.destroy!
        @destroyed += 1
      else
        t.score = 0.0
        t.talking_ids = []
        t.response_count = 0
        t.influencers = {}
        t.save
        @updated += 1
      end
    end

    #time_id = BSON::ObjectId.from_time(Chronic.parse('7 days ago'))
    #topics = Topic.where(:_id.gt => time_id).to_a
    #topics.each do |t|
    #  t.destroy!
    #end

    topics = Topic.all
    topics.each do |t|
      if t.primary_type_id
        primary = Topic.find(t.primary_type_id)
        if primary
          primary.is_topic_type = true
          primary.save
        else
          t.unset_primary_type
          t.save
        end
      end

      t.freebase_repopulate(true, true, true)
    end

    crawlers = CrawlerSource.all
    crawlers.each do |c|
      c.last_modified = nil
      c.last_crawled = nil
      c.etag = nil
      c.posts_added = 0
      c.save
    end

  end
end