object @post
attributes :content, :topic_mentions, :score
attributes :response_count => :talking_count

node :id do |post|
  post.to_param
end

node :_id do |post|
  post.id.to_s
end

node :title do |post|
  post.title_clean
end

node :type do |post|
  post.class.name
end

node :liked do |post|
  post.liked_by?(current_user.id) ? true : false
end

node(:url) do |post|
  "foo"
  #post_url post
end

node(:image) do |post|
  img = nil
  unless post.class.name == 'Talk'
    img = default_image_url(post, 190, 0, 'fit', false, true)
  end

  img ? img.image_url : ''
end

node :primarySource do |post|
  post.sources.first
end

child :user_snippet => :user do |post|
  extends "users/show"
end