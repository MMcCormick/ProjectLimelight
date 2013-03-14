class TopicFetchExternalData

  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight

  def perform(topic_id)
    topic = Topic.find(topic_id)
    topic.freebase_repopulate(true) if topic
  end
end