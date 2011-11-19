class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper TopicsHelper

  cache :trending, :expires_in => 5.minutes

  cache :sidebar_right do |cell,current_user,topic|
    key = topic.id.to_s
    if current_user && current_user.is_following?(topic)
      key += '-following'
    end
    if current_user && can?(:update, @topic)
      key += '-manage'
    end
    key
  end

  def sidebar_right(current_user, topic, connections=nil)
    @current_user = current_user
    @topic = topic
    @connections = connections ? connections : @topic.get_connections
    render
  end

  def add_connection(topic)
    @topic = topic
    @connection_types = TopicConnection.all.asc(:name)
    render
  end

  def trending
    @topics = Topic.all.desc(:pw).limit(40)
    render
  end

end
