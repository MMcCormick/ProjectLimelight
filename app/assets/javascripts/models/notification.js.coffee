class LL.Models.Notification extends Backbone.Model
  url: '/api/notifications'

  initialize: ->

  parse: (resp, xhr) ->
    LL.App.Notifications.findOrCreate(resp.id, resp)