class LL.Models.Post extends Backbone.Model
  url: '/api/posts'

  initialize: ->
    @subscriptions = []

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Posts.findOrCreate(resp.id, new LL.Models.Post(resp))

  scorePretty: ->
    parseInt @get('score')

  subscribed: (event) =>
    _.include(@subscriptions, event)

  subscribe: (event) =>
    unless _.include(@subscriptions, event)
      @subscriptions.push(event)