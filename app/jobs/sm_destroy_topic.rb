class SmDestroyTopic

  @queue = :fast_limelight

  def self.perform(topic_id)
    LlSoulmate.destroy_topic(topic_id)
  end
end