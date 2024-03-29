module TopicsHelper
  def topic_link(topic, alt_name=nil)
    name = alt_name ? alt_name : topic.name
    render 'topics/link', :topic => topic, :name => name
  end

  def topic_default_picture(topic, width, height, mode = 'fit')
    topic_default_picture_path(topic, :w => width, :h => height, :m => mode)
  end
end