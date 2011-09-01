module UsersHelper
  def user_link(user, alt_name=nil)
    name = alt_name ? alt_name : user.username
    render 'users/link', :user => user, :name => name
  end
end
