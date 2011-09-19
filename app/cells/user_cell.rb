class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper

  def sidebar_left
    @user = current_user
    render
  end

  def sidebar_right
    @user = @opts[:user]
    @current_user = current_user

    render
  end

end
