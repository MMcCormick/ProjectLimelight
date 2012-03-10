class LL.Views.InfluenceIncreases extends Backbone.View
  id: 'influence-increases'
  tagName: 'ul'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    self = @

    for influence in @collection.models
      @prependInfluence(influence)

    unless @model.subscribed('influence_change')
      channel = pusher.subscribe(@model.get('_id'));
      channel.bind 'influence_change', (data) ->
        influence = self.collection.get(data.id)
        if influence
          foo = 'bar' # deal with influences already on the strip. move them to the front and update them
        else
          influence = new LL.Models.InfluenceIncrease({
            id: data.id
            amount: data.amount
            topic: LL.App.Topics.findOrCreate(data.topic.id, new LL.Models.Topic(data.topic))
          })
          self.prependInfluence(influence)
      @model.subscribe('influence_change')

    @

  prependInfluence: (influence) =>
    view = new LL.Views.InfluenceIncrease(model: influence)
    $(@el).prepend($(view.render().el).fadeIn(500))