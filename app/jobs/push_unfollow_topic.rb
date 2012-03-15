class PushUnfollowTopic

  @queue = :medium

  def self.perform(user_id, topic_id)
    user = User.find(user_id)
    topic = Topic.find(topic_id)
    user.push_unfollow_topic(topic) if user && topic
  end
end