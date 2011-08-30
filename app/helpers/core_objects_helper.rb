module CoreObjectsHelper
  def parse_mentions(text, object)
    # Loop through all of the topic mentions in the content
    text.scan(/(?<=\[#)(.*?)(?=\])/).flatten(1).each do |topic|
      # Loop through all of the topic mentions connected to this object
      # If we found a match, replace the mention with a link to the topic
      object.topic_mentions.each do |topic_mention|
        if topic_mention.name.to_url == topic.to_url
          text = text.gsub("[##{topic}]", link_to(topic, topic_path(topic_mention)))
        end
      end
    end

    # Loop through all of the user mentions in the content
    text.scan(/(?<=\[@)(.*?)(?=\])/).flatten(1).each do |user|
      # Loop through all of the user mentions connected to this object
      # If we found a match, replace the mention with a link to the user
      object.user_mentions.each do |user_mention|
        if user_mention.username.to_url == user.to_url
          text = text.gsub("[@#{user}]", link_to(user, user_path(user_mention)))
        end
      end
    end

    text.html_safe
  end
end
