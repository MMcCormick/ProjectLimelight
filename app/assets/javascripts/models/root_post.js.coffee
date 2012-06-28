class LL.Models.RootPost extends Backbone.Model

  initialize: ->
    used_ids = []

    @set('post', new LL.Models.Post(@get('post')))