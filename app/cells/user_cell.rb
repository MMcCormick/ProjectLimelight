class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  include ImageHelper

  def sidebar_left
    # TODO: Figure out how to make the helpers available in the cell views, and move this there
    @user = current_user
    @profile_image_url = default_image_url(@user, [85, 65]) if signed_in?

    render
  end

  def sidebar_right
    @user = @opts[:user]

    # TODO: Figure out how to make the helpers available in the cell views, and move this there
    @current_user = current_user

    render
  end

end
