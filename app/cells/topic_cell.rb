class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper TopicsHelper

  def sidebar_right(topic)
    @current_user = current_user
    @topic = topic
    @connections = @topic.get_connections
    render
  end

  def add_connection(topic)
    @topic = topic
    @connections = TopicConnection.all.asc(:name)
    render
  end

end
