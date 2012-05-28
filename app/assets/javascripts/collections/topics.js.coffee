class LL.Collections.Topics extends Backbone.Collection
  url: '/api/topics'
  model: LL.Models.Topic

  convertProtected: (id) ->
    if _.include(['watch'], id)
      "#{id}-protected"
    else
      id