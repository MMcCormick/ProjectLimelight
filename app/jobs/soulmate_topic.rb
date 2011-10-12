require 'json'

class SoulmateTopic
  include Resque::Plugins::UniqueJob
  include Rails.application.routes.url_helpers
  include ImageHelper

  @queue = :soulmate_topic

  def initialize(topics)
    soulmate_data = Array.new
    topics.each do |topic|
      nugget = {
                'id' => topic.id.to_s,
                'term' => topic.name,
                'score' => 0,
                'data' => {
                        'url' => topic_path(topic)
                }}

      if topic.aliases.length > 0
        nugget['aliases'] = topic.aliases
      end

      img = default_image_url(topic, [30, 30])
      if img
        nugget['data']['image'] = img[:url]
      end

      if topic.topic_type_snippets.length > 0
        nugget['data']['types'] = Array.new
        topic.topic_type_snippets.each do |type|
          nugget['data']['types'] << type.name
        end
      end

      soulmate_data << nugget
    end

    Soulmate::Loader.new("topic").load(soulmate_data)
  end

  def self.perform()
    topics = Topic.where(:status => 'Active')
    new(topics)
  end
end