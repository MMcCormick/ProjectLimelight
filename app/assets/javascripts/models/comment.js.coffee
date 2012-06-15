class LL.Models.Comment extends Backbone.Model
  keepInSync: true
  name: 'comment'
  urlRoot: "/api/comments"

  initialize: ->
    if @get('user')
      @set('user', new LL.Models.User(@get('user')))