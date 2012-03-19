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
  user.username.downcase
end

node(:_id) do |user|
  user.id.to_s
end

node(:images) do |user|
  {
          :original => user.image_url(0, 0, 'fit', 'current', true),
          :fit => {
                  :large => user.image_url(695, 0, 'fit'),
                  :medium => user.image_url(190, 0, 'fit')
          },
          :cropped => {
                  :large => user.image_url(300, 300, 'fillcropmid'),
                  :medium => user.image_url(100, 100, 'fillcropmid'),
                  :small => user.image_url(50, 50, 'fillcropmid'),
                  :tiny => user.image_url(30, 30, 'fillcropmid')
          }
  }
end

node(:url) do |user|
  user_url user
end