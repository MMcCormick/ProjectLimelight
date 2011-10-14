module SoulmateHelper
  include Rails.application.routes.url_helpers

  def user_nugget(user)
    nugget = {
              'id' => user.id.to_s,
              'term' => user.username,
              'score' => 0,
              'data' => {
              }
    }

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

    if topic.topic_type_snippets.length > 0
      nugget['data']['types'] = Array.new
      topic.topic_type_snippets.each do |type|
        nugget['data']['types'] << type.name
      end
    end

    nugget
  end
end