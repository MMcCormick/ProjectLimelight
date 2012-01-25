class CoreObjectCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper ApplicationHelper
  helper TopicsHelper
  helper ImageHelper
  helper UsersHelper
  helper VideosHelper

  def teaser_root(current_user, root)
    @current_user = current_user
    @root = root
    render
  end

  def teaser_personal_column(current_user, responses)
    @current_user = current_user
    @responses = responses
    render
  end

  def teaser_personal_list(current_user, responses)
    @current_user = current_user
    @responses = responses
    render
  end

  def sidebar(current_user, object)
    @current_user = current_user
    @object = object
    render
  end

end
