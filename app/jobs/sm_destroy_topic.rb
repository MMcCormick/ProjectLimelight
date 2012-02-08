class SmDestroyTopic

  @queue = :soulmate

  def self.perform(topic_id)
    LLSoulmate.destroy_topic(topic_id)
  end
end