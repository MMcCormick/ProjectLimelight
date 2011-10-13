require 'json'

#TODO: We need to update the soulmate data when relevant topic data changes (alias or type added/removed, etc)
class SmCreateTopic
  include Resque::Plugins::UniqueJob
  include SoulmateHelper

  @queue = :soulmate_topic

  def initialize(topic)
    Soulmate::Loader.new("topic").add(topic_nugget(topic))
  end

  def self.perform(topic_id)
    topic = Topic.find(topic_id)
    new(topic) if topic
  end
end