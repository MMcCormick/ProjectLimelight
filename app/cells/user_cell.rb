class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper

  cache :sidebar do |cell,user,current_user,state|
    current_id = current_user ? current_user.id.to_s : 0
    user_id = user ? user.id.to_s : 0

    if current_id == user_id
      "#{current_id}-mine-#{state}"
    elsif current_user && current_user.is_following?(user)
      "#{user_id}-following"
    else
      user_id
    end
  end

  def sidebar(user, current_user, state)
    @user = user
    @current_user = current_user
    render
  end

end
