class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions

  def sidebar_right(topic)
    @current_user = current_user
    @topic = topic
    render
  end

end
