object @post

attributes :content, :score, :created_at
attributes :response_count => :talking_count

node :type do |post|
  post.class.name
end

node :id do |post|
  post.id.to_s
end

node :slug do |post|
  post.to_param
end

node :title do |post|
  post.title
end

node :liked do |post|
  post.liked_by?(current_user.id) ? true : false
end

node :url do |post|
  post_url post
end

node :created_at_pretty do |post|
  pretty_time(post.created_at)
end

node :video do |post|
  unless post.embed_html.blank?
    video_embed(post.sources[0], 650, 470, nil, nil, post.embed_html, nil)
  end
end

node :video_autoplay do |post|
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

node :images do |post|
  if post.image_versions == 0
    nil
  else
    {
      :original => post.image_url(nil, nil, 'current', true),
      :fit => {
          :large => post.image_url(:fit, :large),
          :normal => post.image_url(:fit, :normal),
          :small => post.image_url(:fit, :small)
      },
      :square => {
          :large => post.image_url(:square, :large),
          :normal => post.image_url(:square, :normal),
          :small => post.image_url(:square, :small)
      }
    }
  end
end

child :user_snippet => :user do |user|
  extends "users/show"
end