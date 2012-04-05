object @topic
attributes :name,
           :slug,
           :score,
           :followers_count

node :type do |t|
  "Topic"
end

node(:id) do |topic|
  topic.id.to_s
end

node(:slug) do |topic|
  topic.slug
end

node(:images) do |topic|
  {
    :original => topic.image_url(nil, nil, 'current', true),
    :fit => {
      :large => topic.image_url(:fit, :large),
      :normal => topic.image_url(:fit, :normal),
      :small => topic.image_url(:fit, :small)
    },
    :square => {
      :large => topic.image_url(:square, :large),
      :normal => topic.image_url(:square, :normal),
      :small => topic.image_url(:square, :small)
    }
  }
end