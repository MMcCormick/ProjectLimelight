object @post

if @_data.class.name == 'Topic'
  extends "topics/show"
else
  extends "posts/show"
end