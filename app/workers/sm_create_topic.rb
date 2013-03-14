class SmCreateTopic

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(topic_id)
    topic = Topic.find(topic_id)
    LlSoulmate.create_topic(topic) if topic
  end
end