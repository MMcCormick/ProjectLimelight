class TopicFetchExternalData

  @queue = :slow_limelight

  def self.perform(topic_id)
    topic = Topic.find(topic_id)
    topic.freebase_repopulate(true) if topic
  end
end