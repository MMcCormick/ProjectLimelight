class LL.Collections.InfluenceIncreases extends Backbone.Collection
  model: LL.Models.InfluenceIncrease
  url: '/api/users/influence_increases'

  findOrCreate: (id, data=null) ->
    model = @get(id)

    # set it to data if we're passing in a model
    model = data unless model

    unless model
      model = new LL.Models.InfluenceIncrease
      model.fetch({data: {id: id}})

    @add(model) unless @get(model.get('id'))

    model