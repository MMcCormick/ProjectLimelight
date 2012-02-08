class PushFollowTopic

  @queue = :feeds

  def self.perform(user_id, topic_id)
    user = User.find(user_id)
    topic = Topic.find(topic_id)
    user.push_follow_topic(topic) if user && topic
  end
end