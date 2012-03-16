object @post

attributes :public_talking, :personal_talking

child :root => :root do
  extends "posts/root"
end

child :like_responses => :like_responses do
  extends "posts/show"
end

child :activity_responses => :activity_responses do
  extends "posts/show"
end

child :public_responses => :public_responses do
  extends "posts/show"
end

child :personal_responses => :personal_responses do
  extends "posts/show"
end