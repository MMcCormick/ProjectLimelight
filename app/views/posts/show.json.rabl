object @post
attributes :content, :score, :created_at
attributes :response_count => :talking_count

node :type do |post|
  post.class.name
end

node :id do |post|
  post.to_param
end

node :_id do |post|
  post.id.to_s
end

node :title do |post|
  post.title_clean
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

child :topic_mentions => :topic_mentions do
  extends "topics/show"
end

node(:images) do |post|
  if post.image_versions == 0
    nil
  else
    {
            :original => post.image_url(0, 0, 'fit', 'current', true),
            :fit => {
                    :large => post.image_url(695, 0, 'fit'),
                    :medium => post.image_url(190, 0, 'fit')
            },
            :cropped => {
                    :large => post.image_url(300, 300, 'fillcropmid'),
                    :medium => post.image_url(100, 100, 'fillcropmid'),
                    :small => post.image_url(50, 50, 'fillcropmid'),
                    :tiny => post.image_url(30, 30, 'fillcropmid')
            }
    }
  end
end

child :user_snippet => :user do |user|
  extends "users/show"
end