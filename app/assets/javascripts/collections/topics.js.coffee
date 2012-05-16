class LL.Collections.Topics extends Backbone.Collection
  url: '/api/topics'
  model: LL.Models.Topic

  convertProtected: (id) ->
    if _.include(['watch'], id)
      "#{id}-protected"
    else
      id

  findOrCreate: (id, data=null, forceLookup=false) ->
    id = @convertProtected(id)

    model = @get(id)
    console.log id
    console.log @
    console.log model

    if model
      if forceLookup == true
        model.fetch({data: {id: id}, success: (model, response) -> model.set(response) })
      return model

    if data
      model = new LL.Models.Topic(data)
      model.id = id

    unless model
      model = new LL.Models.Topic
      model.id = id
      model.fetch({data: {id: id}})

    @add(model)

    model