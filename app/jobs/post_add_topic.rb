class PostAddTopic

  @queue = :slow

  def self.perform(post_id, topic_id)
    post = Post.find(post_id)
    topic = Topic.find(topic_id)

    FeedUserItem.push_post_through_topic(post, topic)
    FeedTopicItem.push_post_through_topic(post, topic)
    FeedLikeItem.update_post_topics(post)
    FeedContributeItem.update_post_topics(post)


  end
end