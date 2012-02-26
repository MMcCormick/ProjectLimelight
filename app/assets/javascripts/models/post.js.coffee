class LL.Models.Post extends Backbone.Model
  url: '/api/posts'

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Posts.findOrCreate(resp.id, new LL.Models.Posts(resp))