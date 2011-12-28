class UserCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper
  helper TopicsHelper

  cache :sidebar do |cell,user,current_user,state|
    current_id = current_user ? current_user.id.to_s : 0
    user_id = user ? user.id.to_s : 0

    if current_id == user_id
      "#{current_id}-mine"
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

  def interests(user)
    @interests = Neo4j.user_interests(user.id.to_s, 6)
    render
  end

  def topic_suggestions(user)
    @suggestions = Neo4j.user_topic_suggestions(user.id.to_s, 6)
    render
  end

end
