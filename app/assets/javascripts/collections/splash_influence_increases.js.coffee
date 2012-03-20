class LL.Collections.SplashInfluenceIncreases extends Backbone.Collection
  model: LL.Models.InfluenceIncrease
  url: '/api/influence_increases'

  findOrCreate: (id, data=null) ->
    model = @get(id)

    return model if model

    if data
      model = new LL.Models.InfluenceIncrease(data)
      model.id = id

    unless model
      model = new LL.Models.InfluenceIncrease
      model.fetch({data: {id: id}})

    @add(model)

    model