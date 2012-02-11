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
    @invite = InviteCode.where(user_id: @user.id).first
    @invite = InviteCode.create(:user_id => @user.id, :allotted => 3) unless @invite

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

  def tutorial_1(current_user)
    @current_user = current_user
    render
  end

  def tutorial_2(current_user)
    @current_user = current_user
    render
  end

  def tutorial_3(current_user)
    @current_user = current_user
    suggestions = Neo4j.user_topic_suggestions(@current_user.id.to_s, 4)
    @suggestions = []
    suggestions.each do |s|
      @suggestions << TopicSnippet.new(s)
    end
    render
  end

  def tutorial_4(current_user)
    @current_user = current_user
    render
  end

end
