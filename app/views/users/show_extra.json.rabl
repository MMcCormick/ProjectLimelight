object @user

extends "users/show"

attributes :following_users,
           :following_topics,
           :tutorial_step

node :invite_code do |user|
  if user.invite_code_id
    code = InviteCode.find(user.invite_code_id)
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