object @post
attributes :id, :content
attributes :response_count => :talking_count

node :title do |post|
  post.title_clean
end

node :type do |post|
  post.class.name
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

child :user_snippet => :user do |post|
  extends "users/show"
end