class CoreObjectCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper ApplicationHelper
  helper TopicsHelper
  helper ImageHelper

  def sidebar_right(current_user, object)
    @current_user = current_user
    @object = object
    render
  end

end
