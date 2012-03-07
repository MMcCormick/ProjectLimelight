class LL.Models.User extends Backbone.Model
  url: '/api/users'

  initialize: ->
    @subscriptions = []

  parse: (resp, xhr) ->
    LL.App.Users.findOrCreate(resp.id, new LL.Models.User(resp))

  following: (model) ->
    if model.constructor.name == 'User'
      _.include(@get('following_users'), model.get('_id'))
    else if model.constructor.name == 'Topic'
      _.include(@get('following_topics'), model.get('_id'))
    else
      false

  scorePretty: ->
    parseInt @get('score')

  subscribed: (event) =>
    _.include(@subscriptions, event)

  subscribe: (event) =>
    unless _.include(@subscriptions, event)
      @subscriptions.push(event)