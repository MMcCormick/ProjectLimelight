object @post

child :root => :root do
  extends "posts/root"
end

child :responses => :responses do
  extends "posts/show"
end