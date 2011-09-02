class UserCell < Cell::Rails

  include Devise::Controllers::Helpers

  def sidebar_left
    @user = current_user
    render
  end

  def sidebar_right
    @current_user = current_user
    @user = @opts[:user]
    render
  end

end
