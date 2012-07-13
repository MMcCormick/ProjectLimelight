class PostRemoveTopic

  @queue = :slow

  def self.perform(post_id, topic_id)
    post = Post.find(post_id)
    topic = Topic.find(topic_id)

    FeedUserItem.unpush_post_through_topic(post, topic)
    FeedTopicItem.unpush_post_through_topic(post, topic)
    FeedContributeItem.update_post_topics(post)
  end
end