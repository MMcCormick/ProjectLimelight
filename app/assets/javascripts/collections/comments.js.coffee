class LL.Collections.Comments extends Backbone.Collection
  model: LL.Models.Comment
  url: '/api/comments'

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
      model = new LL.Models.Comment
      model.fetch({data: {id: id}})

    @add(model)

    model