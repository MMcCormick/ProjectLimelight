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

node(:type) do |user|
  'User'
end

node(:id) do |user|
  user.id.to_s
end

node(:slug) do |user|
  user.username.downcase
end

node(:images) do |user|
  {
    :original => user.image_url(nil, nil, 'current', true),
    :fit => {
      :large => user.image_url(:fit, :large),
      :normal => user.image_url(:fit, :normal),
      :small => user.image_url(:fit, :small)
    },
    :square => {
      :small => user.image_url(:square, :small)
    }
  }
end

node(:url) do |user|
  user_url user
end