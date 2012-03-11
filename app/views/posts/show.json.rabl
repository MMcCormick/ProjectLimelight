object @post
attributes :content, :score, :created_at
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
  post_url post
end

node(:created_at_pretty) do |post|
  pretty_time(post.created_at)
end

# Thumbnail image for feeds
node(:image) do |post|
  post.image_url(190, 0, 'fit')
end

# Larger image for show pages and the modal show
node(:image_show) do |post|
  post.image_url(695, 0, 'fit')
end

node(:video) do |post|
  unless post.embed_html.blank?
    video_embed(post.sources[0], 650, 470, nil, nil, post.embed_html, nil)
  end
end

node(:video_autoplay) do |post|
  unless post.embed_html.blank?
    video_embed(post.sources[0], 650, 470, nil, nil, post.embed_html, true)
  end
end

node :primarySource do |post|
  post.sources.first
end

node :topic_mentions do |post|
  post.topic_mentions.sort {|x,y| y.score <=> x.score }
end

child :user_snippet => :user do |post|
  extends "users/show"
end