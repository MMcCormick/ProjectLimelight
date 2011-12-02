module ApplicationHelper

  # Return a title on a per-page basis.
  def title
    base_title = "Limelight"
    if @title.nil?
      base_title
    else
      "#{@title} | #{base_title}"
    end
  end

  # Return the page load time (defined in application_controller.rb init)
  def load_time
    "#{(Time.now-@start_time).round(4)}s"
  end

  # Parse text via markdown
  def markdown(text)
    options = [:hard_wrap, :autolink, :no_intraemphasis, :strikethrough]
    Redcarpet.new(text, *options).to_html.html_safe
  end

  def output_errors(errors)
    error_string = ''
    errors.each do |field_name, error|
      error_string += "<div class='error'>#{field_name} #{error}</div>"
    end
    unless error_string.blank?
      "<div class='errors'>#{error_string}</div>".html_safe
    end
  end

  def parse_mentions(text, object, absolute=false)
    # Loop through all of the topic mentions in the content
    text.scan(/\#\[([0-9a-zA-Z]+)#([a-zA-Z0-9,!\-_:'&\?\$ ]+)\]/).each do |topic|
      # Loop through all of the topic mentions connected to this object
      # If we found a match, replace the mention with a link to the topic
      topic_mention = object.topic_mentions.detect{|m| m.id.to_s == topic[0]}
      if topic_mention
        if absolute
          text.gsub!(/\#\[#{topic[0]}##{topic[1]}\]/, "[#{topic[1]}](#{topic_url(topic_mention)})")
        else
          text.gsub!(/\#\[#{topic[0]}##{topic[1]}\]/, "[#{topic[1]}](#{topic_path(topic_mention)})")
        end
      else
        text.gsub!(/\#\[#{topic[0]}##{topic[1]}\]/, topic[1])
      end
    end

    # Loop through all of the user mentions in the content
    text.scan(/\@\[([0-9a-zA-Z]+)#([\w ]+)\]/).each do |user|
      # Loop through all of the user mentions connected to this object
      # If we found a match, replace the mention with a link to the user
      user_mention = object.user_mentions.detect{|m| m.id = user[0]}
      if user_mention
        if absolute
          text.gsub!(/\@\[#{user[0]}##{user[1]}\]/, "[#{user_mention.username}](#{user_url(user_mention)})")
        else
          text.gsub!(/\@\[#{user[0]}##{user[1]}\]/, "[#{user_mention.username}](#{user_path(user_mention)})")
        end
      else
        text.gsub!(/\@\[#{user[0]}##{user[1]}\]/, user_mention.username)
      end
    end

    # Loop through all of the topic short names in the content
    text.scan(/\#([0-9a-zA-Z&]+)/).each do |topic|
      # Loop through all of the topic mentions connected to this object
      # If we found a match, replace the mention with a link to the topic
      topic_mention = object.topic_mentions.detect{|m| m.short_name == topic[0]}
      if topic_mention
        if absolute
          text.gsub!(/\##{topic[0]}/, "[##{topic[0]}](#{topic_url(topic_mention)})")
        else
          text.gsub!(/\##{topic[0]}/, "[##{topic[0]}](#{topic_path(topic_mention)})")
        end
      else
        text.gsub!(/\##{topic[0]}/, topic[0])
      end
    end

    # Replace any messed up mentions
    text.gsub!(/\#\[(.*)\]/, "\\1")

    # Replace any messed up short names
    #text.gsub!(/\#([a-zA-Z0-9]*)/, "\\1")

    text.html_safe
  end

  def show_more(text, length)
    if text.length > length
      "<div class='show-more'>#{text[0..length]}<span class='extra hide'>#{text[length..text.length]}</span><span class='more'>... show more</span></div>".html_safe
    else
      text
    end
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

  # Generate a random hint
  def generate_hint
    hints = [
      "You can use the arrow keys to navigate feeds.",
      "Limelight <3 shortcuts. Press shift+up or shift+down to vote on a highlighted post. <span id='shortcuts'>See All Shortcuts.</span>",
      "Mention a user in a post with @username or a topic with #topic name. Spaces allowed!",
      "Post interesting stuff to up your popularity.",
      "Got a big screen? Try the grid view and put that space to use! Just click the grid button on the top right.",
      "You can double click a feed filter to turn all of the other filters off.",
      "If there is only one filter on and you turn it off all of the filters will turn on."
    ]

    choice = rand(hints.length+5)
    hints.length > choice ? hints[choice] : nil
  end

  # show the splash page to new users
  def new_user_splash
    unless signed_in? || cookies[:shown_splash] == 'true'
      cookies.permanent[:shown_splash] = true
      "<div id='show_splash'></div>".html_safe
    end
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