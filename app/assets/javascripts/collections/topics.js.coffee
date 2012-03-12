class LL.Collections.Topics extends Backbone.Collection
  model: LL.Models.Topic

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    model = new LL.Models.Topic(data) unless model

    unless model
      model = new LL.Models.Topic
      model.fetch({data: {id: id}})

    @add(model)

    model