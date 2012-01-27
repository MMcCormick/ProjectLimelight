class CoreObjectCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper ApplicationHelper
  helper TopicsHelper
  helper ImageHelper
  helper UsersHelper
  helper VideosHelper

  def teaser_root_column(current_user, root)
    @current_user = current_user
    @root = root
    render
  end

  def teaser_root_list(current_user, root)
    @current_user = current_user
    @root = root
    render
  end

  def teaser_personal_column(current_user, root, responses)
    @current_user = current_user
    @root = root
    @responses = responses
    render
  end

  def teaser_personal_list(current_user, root, responses)
    @current_user = current_user
    @root = root
    @responses = responses
    render
  end

  def teaser_public_column(current_user, root)
    @current_user = current_user
    @root = root
    @response = Talk.where(:root_id => root.id).order_by(:created_at, :desc).first
    render
  end

  def teaser_public_list(current_user, root)
    @current_user = current_user
    @root = root
    @response = Talk.where(:root_id => root.id).order_by(:created_at, :desc).first
    render
  end

  def sidebar(current_user, object)
    @current_user = current_user
    @object = object
    render
  end

end
