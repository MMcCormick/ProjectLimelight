class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper TopicsHelper

  def sidebar_right(topic, connections=nil)
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

end
