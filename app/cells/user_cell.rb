class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper
  cache :sidebar_left do |cell,user|
    user ? user.id.to_s : 0
  end
  cache :sidebar_right do |cell,current_user,user|
    if current_user && current_user.is_following?(user)
      "#{user.id.to_s}-following"
    else
      user.id.to_s
    end

  end

  def sidebar_left(user)
    @user = user
    render
  end

  def sidebar_right(current_user, user)
    @user = user
    @current_user = current_user
    render
  end

end
