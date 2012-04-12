class LL.Models.User extends Backbone.Model
  url: '/api/users'

  initialize: ->

  parse: (resp, xhr) ->
    LL.App.Users.findOrCreate(resp.id, new LL.Models.User(resp))

  following: (model) ->
    if model.get('type') == 'User'
      _.include(@get('following_users'), model.get('id'))
    else if model.get('type') == 'Topic'
      _.include(@get('following_topics'), model.get('id'))
    else
      false

  scorePretty: ->
    parseInt @get('score')

  hasRole: (role) ->
    _.include(@get('roles'), role)
