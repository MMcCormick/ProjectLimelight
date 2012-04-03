object @topic
attributes :name,
           :slug,
           :score,
           :followers_count

node :type do |t|
  "Topic"
end

node(:id) do |topic|
  topic.slug
end

node(:_id) do |topic|
  topic.id.to_s
end

node(:images) do |topic|
  if topic.image_versions == 0
    {
      :original => "#{S3['image_prefix']}/defaults/topic_original.gif",
      :fit => {
        :large => "#{S3['image_prefix']}/defaults/topic_large.gif",
        :normal => "#{S3['image_prefix']}/defaults/topic_normal.gif",
        :small => "#{S3['image_prefix']}/defaults/topic_small.gif",
      },
      :square => {
        :large => "#{S3['image_prefix']}/defaults/topic_large.gif",
        :normal => "#{S3['image_prefix']}/defaults/topic_medium.gif",
        :small => "#{S3['image_prefix']}/defaults/topic_small.gif",
      }
    }
  else
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
end