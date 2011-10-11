module CoreObjectsHelper
  def parse_mentions(text, object)
    # Loop through all of the topic mentions in the content
    text.scan(/\#\[([0-9a-zA-Z]*)#([\w ]*)\]/).each do |topic|
      # Loop through all of the topic mentions connected to this object
      # If we found a match, replace the mention with a link to the topic
      object.topic_mentions.each do |topic_mention|
        if topic_mention.id.to_s == topic[0]
          text.gsub!(/\#\[#{topic[0]}##{topic[1]}\]/, topic_link(topic_mention))
        end
      end
    end

    # Loop through all of the user mentions in the content
    text.scan(/\@\[([0-9a-zA-Z]*)#([\w ]*)\]/).each do |user|
      # Loop through all of the user mentions connected to this object
      # If we found a match, replace the mention with a link to the user
      object.user_mentions.each do |user_mention|
        if user_mention.id.to_s == user[0]
          text.gsub!(/\@\[#{user[0]}##{user[1]}\]/, user_link(user_mention))
        end
      end
    end

    text.html_safe
  end
end
