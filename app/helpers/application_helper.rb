module ApplicationHelper

  # Return a title on a per-page basis.
  def title
    base_title = "Limelight"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end

  # Return the page load time (defined in application_controller.rb init)
  def load_time
    "#{(Time.now-@start_time).round(4)}s"
  end

  # Parse text via markdown
  def markdown(text)
    options = [:hard_wrap, :filter_html, :autolink, :no_intraemphasis, :strikethrough]
    Redcarpet.new(text, *options).to_html.html_safe
  end

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

  # Devise helper
  # https://github.com/plataformatec/devise/wiki/How-To:-Display-a-custom-sign_in-form-anywhere-in-your-app
  def resource_name
    :user
  end

  # Devise helper
  def resource
    @resource ||= User.new
  end

  # Devise helper
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def static_data
    data = {
            :fetchEmbedUrl => embedly_fetch_path,
            :myId => signed_in? ? current_user.id.to_s : 0,
            :autocomplete => '/soul-data/search',
            :userAutoBucket => signed_in? ? current_user.id.to_s : 0,
            :feedFiltersUpdate => feed_update_url
    }
    Yajl::Encoder.encode(data)
  end

end