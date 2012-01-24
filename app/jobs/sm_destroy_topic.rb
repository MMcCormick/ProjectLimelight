require 'json'

class SmDestroyTopic
  include Resque::Plugins::UniqueJob

  @queue = :soulmate

  def self.perform(topic_id)
    Soulmate::Loader.new("topic").remove({'id' => topic_id})
  end
end