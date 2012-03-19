class LL.Collections.Topics extends Backbone.Collection
  url: '/api/topics'
  model: LL.Models.Topic

  convertProtected: (id) ->
    if _.include(['watch'], id)
      "#{id}-protected"
    else
      id

  findOrCreate: (id, data=null) ->
    id = @convertProtected(id)

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