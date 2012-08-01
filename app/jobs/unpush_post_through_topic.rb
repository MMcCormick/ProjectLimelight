class UnpushPostThroughTopic

  @queue = :medium_limelight

  def self.perform(post_id, topic_id)
    post = PostMedia.find(post_id)
    topic = Topic.find(topic_id)

    if post && topic
      FeedUserItem.unpush_post_through_topic(post, topic)
    end
  end
end