object @topic
attributes :name,
           :slug,
           :score

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
                    :medium => "#{S3['image_prefix']}/defaults/topic_medium.gif",
            },
            :cropped => {
                    :large => "#{S3['image_prefix']}/defaults/topic_large.gif",
                    :medium => "#{S3['image_prefix']}/defaults/topic_medium.gif",
                    :small => "#{S3['image_prefix']}/defaults/topic_small.gif",
                    :tiny => "#{S3['image_prefix']}/defaults/topic_tiny.gif",
            }
    }
  else
    {
            :original => topic.image_url(0, 0, 'fit', 'current', true),
            :fit => {
                    :large => topic.image_url(695, 0, 'fit'),
                    :medium => topic.image_url(165, 0, 'fit')
            },
            :cropped => {
                    :large => topic.image_url(300, 300, 'fillcropmid'),
                    :medium => topic.image_url(100, 100, 'fillcropmid'),
                    :small => topic.image_url(50, 50, 'fillcropmid'),
                    :tiny => topic.image_url(30, 30, 'fillcropmid')
            }
    }
  end
end