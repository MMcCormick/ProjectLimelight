class LL.Models.Notification extends Backbone.Model
  url: '/api/notifications'
  keepInSync: true
  name: 'notification'

  initialize: ->
    if @get('object')
      @set('object', new LL.Models.Post(@get('object')))

    if @get('object_user')
      @set('object_user', new LL.Models.Post(@get('object_user')))

    if @get('triggered_by')
      @set('triggered_by', new LL.Models.User(@get('triggered_by')))