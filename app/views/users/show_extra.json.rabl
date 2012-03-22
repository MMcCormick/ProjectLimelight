object @user

extends "users/show"

attributes :following_users,
           :following_topics,
           :tutorial_step,
           :tutorial1_step

node :invite_code do |user|
  code = InviteCode.where(:user_id => user.id).first
  if code
    {:code => code.code, :remaining => code.remaining}
  else
    {}
  end
end

node :facebook_connected do |user|
  user.get_social_connect('facebook') ? true : false
end

node :twitter_connected do |user|
  user.get_social_connect('twitter') ? true : false
end