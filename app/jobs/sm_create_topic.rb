require 'json'

#TODO: We need to update the soulmate data when relevant topic data changes (alias or type added/removed, etc)
class SmCreateTopic
  include Resque::Plugins::UniqueJob
  include Rails.application.routes.url_helpers
  include ImageHelper

  @queue = :soulmate_topic

  def initialize(topic)
    nugget = {
              'id' => topic.id.to_s,
              'term' => topic.name,
              'score' => 0,
              'data' => {
                      'url' => topic_path(topic)
              }
    }

    if topic.aliases.length > 0
      nugget['aliases'] = topic.aliases
    end

    img = default_image_url(topic, [25, 25])
    nugget['data']['image'] = img[:url] if img

    if topic.topic_type_snippets.length > 0
      nugget['data']['types'] = Array.new
      topic.topic_type_snippets.each do |type|
        nugget['data']['types'] << type.name
      end
    end

    Soulmate::Loader.new("topic").add(nugget)
  end

  def self.perform(topic_id)
    topic = Topic.find(topic_id)
    new(topic) if topic
  end
end