class LL.Collections.InfluenceIncreases extends Backbone.Collection
  model: LL.Models.InfluenceIncrease
  url: '/api/users/influence_increases'

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    model = data unless model

    unless model
      model = new LL.Models.InfluenceIncrease
      model.fetch({data: {id: id}})

    @add(model)

    model