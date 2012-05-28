class LL.Models.Comment extends Backbone.Model
  url: '/api/comments'
  keepInSync: true
  name: 'comment'

  initialize: ->
    if @get('user')
      @set('user', new LL.Models.User(@get('user')))