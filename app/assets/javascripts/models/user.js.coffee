class LL.Models.User extends Backbone.Model
  keepInSync: true
  name: 'user'
  urlRoot: "/api/users"

  initialize: ->

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
