module TopicsHelper
  def topic_link(topic, alt_name=nil)
    name = alt_name ? alt_name : topic.name
    render 'topics/link', :topic => topic, :name => name
  end
end
