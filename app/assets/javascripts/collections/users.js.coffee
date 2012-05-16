class LL.Collections.Users extends Backbone.Collection
  model: LL.Models.User

  findOrCreate: (id, data=null, forceLookup=false) ->
    model = @get(id)

    if model
      if forceLookup == true
        model.fetch({data: {id: id}, success: (model, response) -> model.set(response) })
      else if data
        model.set(data)
      return model

    if data
      model = data
      model.id = id

    unless model
      model = new LL.Models.User
      model.id = id
      model.fetch({data: {id: id}})

    @add(model)

    model