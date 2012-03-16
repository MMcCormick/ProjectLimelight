class LL.Collections.Topics extends Backbone.Collection
  url: '/api/topics'
  model: LL.Models.Topic

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    if data
      model = new LL.Models.Topic(data)
      model.id = id

    unless model
      model = new LL.Models.Topic
      model.fetch({data: {id: id}})

    @add(model)

    model