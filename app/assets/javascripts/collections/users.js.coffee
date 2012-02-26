class LL.Collections.Users extends Backbone.Collection
  model: LL.Models.User

  findOrCreate: (id, data=null) ->
    model = @get(id)

    # set it to data if we're passing in a model
    model = data unless model

    unless model
      model = new LL.Models.User
      model.fetch({data: {id: id}})

    @add(model) unless @get(model.get('id'))

    model