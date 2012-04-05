object @notification

attributes :read,
           :type,
           :user_id,
           :message,
           :created_at

node(:id) do |n|
  n.id.to_s
end

node(:created_at_pretty) do |n|
  pretty_time(n.created_at)
end

node(:created_at_day) do |n|
  pretty_day(n.created_at)
end

node :sentence do |n|
  n.notification_text
end

child :object => :object do |n|
  extends "posts/show_snippet"
end

child :triggered_by => :triggered_by do |n|
  extends "users/show"
end

child :object_user => :object_user do |n|
  extends "users/show"
end
