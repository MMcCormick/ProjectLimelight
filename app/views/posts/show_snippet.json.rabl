object @post

attributes :public_id, :created_at

node :type do |post|
  post.type
end

node :id do |post|
  post.id.to_s
end

node :slug do |post|
  post.to_param
end