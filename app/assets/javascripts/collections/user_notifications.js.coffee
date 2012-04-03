class LL.Collections.UserNotifications extends Backbone.Collection
  url: '/api/users/notifications'
  model: LL.Models.Notification

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    model = new LL.Models.Notification(data) unless model

    unless model
      model = new LL.Models.Notification
      model.fetch({data: {id: id}})

    @add(model)

    model