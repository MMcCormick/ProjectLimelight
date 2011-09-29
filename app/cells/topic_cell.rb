class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions

  def sidebar_right
    @current_user = current_user
    @topic = @opts[:topic]
    render
  end

end
