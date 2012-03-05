class LL.Collections.UserTopicInfluences extends Backbone.Collection
  model: LL.Models.TopicInfluence

  findOrCreate: (id, data=null) ->
    model = @get(id)

    # set it to data if we're passing in a model
    model = data unless model

    unless model
      model = new LL.Models.TopicInfluence
      model.fetch({data: {id: id}})

    @add(model) unless @get(model.get('id'))

    model