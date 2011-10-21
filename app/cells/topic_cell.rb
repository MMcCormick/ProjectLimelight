class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions

  def sidebar_right(topic)
    @current_user = current_user
    @topic = topic
    render
  end

  def add_connection(topic)
    @topic = topic
    @connections = TopicConnection.all.asc(:name)
    render
  end

end
