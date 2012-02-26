class LL.Models.User extends Backbone.Model
  url: '/api/users'

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Users.findOrCreate(resp.id, new LL.Models.User(resp))