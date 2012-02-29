object @user
attributes :username,
           :first_name,
           :last_name,
           :score,
           :following_users_count,
           :following_topics_count,
           :followers_count,
           :unread_notification_count,
           :public_id,
           :slug

node(:id) do |user|
  user.username.downcase
end

node(:_id) do |user|
  user.id.to_s
end

node(:url) do |user|
  user_url user
end

node(:score_pretty) do |user|
  user.score.to_i if user.class.name == 'User'
end