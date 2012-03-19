class LL.Models.User extends Backbone.Model
  url: '/api/users'

  initialize: ->

  parse: (resp, xhr) ->
    LL.App.Users.findOrCreate(resp.id, new LL.Models.User(resp))

  following: (model) ->
    console.log model.constructor.name
    if model.constructor.name == 'User'
      _.include(@get('following_users'), model.get('_id'))
    else if model.constructor.name == 'Topic'
      _.include(@get('following_topics'), model.get('_id'))
    else
      false

  scorePretty: ->
    parseInt @get('score')