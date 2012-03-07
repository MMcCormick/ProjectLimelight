class LL.Views.InfluenceIncreases extends Backbone.View
  id: 'influence-increases'
  tagName: 'ul'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    $(@el)

    for influence in @collection.models
      @prependInfluence(influence)

    @

  prependInfluence: (influence) =>
    view = new LL.Views.InfluenceIncrease(model: influence)
    $(@el).prepend(view.render().el)