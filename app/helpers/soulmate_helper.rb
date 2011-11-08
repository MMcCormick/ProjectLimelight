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
                      'slug' => topic.slug
              }
    }

    if topic.aliases.length > 0
      nugget['aliases'] = topic.aliases
    end

    if topic.get_types.length > 0
      nugget['data']['types'] = Array.new
      topic.get_types.each do |type|
        nugget['data']['types'] << type.topic_name
      end
    end

    nugget
  end
end