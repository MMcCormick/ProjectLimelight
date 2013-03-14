class SmDestroyTopic

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(topic_id)
    LlSoulmate.destroy_topic(topic_id)
  end
end