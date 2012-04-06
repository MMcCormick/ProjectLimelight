class LL.Models.Comment extends Backbone.Model
  url: '/api/comments'

  initialize: ->
    if @get('user')
      @set('user', LL.App.Users.findOrCreate(@get('user').id, new LL.Models.User(@get('user'))))