class SmDestroyTopic

  @queue = :soulmate

  def self.perform(topic_id)
    LlSoulmate.destroy_topic(topic_id)
  end
end