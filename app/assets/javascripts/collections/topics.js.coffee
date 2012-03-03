class LL.Collections.Topics extends Backbone.Collection
  model: LL.Models.Topic

  findOrCreate: (id, data=null) ->
    model = @get(id)

    # set it to data if we're passing in a model
    model = data unless model

    unless model
      model = new LL.Models.Topic
      model.fetch({data: {id: id}})

    @add(model)

    model