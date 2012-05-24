class TestJob

  @queue = :fast

  def self.perform()
    Post.all.destroy
    FeedUserItem.all.delete
    FeedTopicItem.all.delete
    FeedContributeItem.all.delete
    PopularityAction.all.delete

    User.update_all(:score => 0)
    Topic.update_all(:score => 0)

    @destroyed = 0
    @updated = 0
    topics = Topic.deleted.all
    topics.each do |t|
      primary_for = Topic.where(:primary_type_id => t.id)
      if primary_for.length > 0 || t.followers_count == 0 && !t.primary_type_id && !t.fb_page_id && !t.is_category && t.image_versions == 0
        t.destroy!
        @destroyed += 1
      else
        t.talking_ids = []
        t.response_count = 0
        t.influencers = {}
        t.save
        @updated += 1
      end
    end

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
    end

  end
end