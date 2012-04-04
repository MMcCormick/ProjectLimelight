class LL.Collections.Users extends Backbone.Collection
  model: LL.Models.User

  findOrCreate: (id, data=null) ->
    model = @get(id)

    if model
      if data
        model.set(data)
      return model

    if data
      model = data
      model.id = id

    unless model
      model = new LL.Models.User
      model.fetch({data: {id: id}})

    @add(model)

    model