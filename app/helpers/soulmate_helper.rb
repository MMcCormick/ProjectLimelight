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
      nugget['aliases'] ||= Array.new
      topic.aliases.each do |data|
        nugget['aliases'] << data.name
      end
    end

    topic.get_types.each do |type|
      if type.primary
        nugget['data']['types'] ||= Array.new
        nugget['data']['types'] << type.topic_name
      end
    end

    nugget
  end
end