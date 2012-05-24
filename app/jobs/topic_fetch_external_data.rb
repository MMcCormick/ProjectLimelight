class TopicFetchExternalData

  @queue = :slow

  def self.perform(topic_id)
    topic = Topic.find(topic_id)
    topic.fetch_freebase(true) if topic
  end
end