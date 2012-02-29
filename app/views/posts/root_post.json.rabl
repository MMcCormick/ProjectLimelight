object @post

attributes :public_talking, :personal_talking

child :root => :root do
  extends "posts/root"
end

child :responses => :responses do
  extends "posts/show"
end