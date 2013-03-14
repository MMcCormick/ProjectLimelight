class PushUnfollowTopic

  include Sidekiq::Worker
  sidekiq_options :queue => :medium_limelight

  def perform(user_id, topic_id)
    user = User.find(user_id)
    topic = Topic.find(topic_id)
    user.push_unfollow_topic(topic) if user && topic
  end
end