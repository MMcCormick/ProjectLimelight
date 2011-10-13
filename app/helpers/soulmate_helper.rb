include ImageHelper

module SoulmateHelper
  include Rails.application.routes.url_helpers

  def user_nugget(user)
    nugget = {
              'id' => user.id.to_s,
              'term' => user.username,
              'score' => 0,
              'data' => {
                      'url' => user_path(user)
              }
    }

    img = default_image_url(user, [25, 25])
    nugget['data']['image'] = img[:url] if img
    nugget
  end

  def topic_nugget(topic)
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

    nugget
  end
end