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