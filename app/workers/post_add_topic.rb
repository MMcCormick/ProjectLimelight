class PostAddTopic

  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight

  def perform(post_id, topic_id)
    post = Post.find(post_id)
    topic = Topic.find(topic_id)

    FeedUserItem.push_post_through_topic(post, topic)
  end
end