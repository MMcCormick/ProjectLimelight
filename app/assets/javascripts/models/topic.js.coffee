class LL.Models.Topic extends Backbone.Model
  url: '/api/topics'

  initialize: ->
    @subscriptions = []

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Topics.findOrCreate(resp.id, new LL.Models.Topic(resp))

  scorePretty: ->
    parseInt @get('score')

  subscribed: (event) =>
      _.include(@subscriptions, event)

  subscribe: (event) =>
    unless _.include(@subscriptions, event)
      @subscriptions.push(event)