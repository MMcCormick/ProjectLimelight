class LL.Collections.Users extends Backbone.Collection
  model: LL.Models.User

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    if data
      model = new LL.Models.User(data)
      model.id = id

    unless model
      model = new LL.Models.User
      model.fetch({data: {id: id}})

    @add(model)

    model