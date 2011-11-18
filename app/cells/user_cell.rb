class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper
  cache :sidebar_left do |cell,user|
    user ? user.id.to_s : 0
  end
  cache :sidebar_right do |cell,user|
    user.id.to_s
  end

  def sidebar_left(user)
    @user = user
    render
  end

  def sidebar_right(user)
    @user = user
    @current_user = current_user
    render
  end

end
