class LL.Views.InfluenceIncreasesFull extends Backbone.View
  tagName: 'ul'
  id: 'influence-increases-full'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>

    self = @

    if @collection.models.length == 0
      $(@el).html('<li class="none">This section updates as you gain influence in topics</li>')

    for influence in @collection.models
      @appendInfluence(influence)

    $(@el).find('li').last().addClass('last')

    @

  appendInfluence: (influence) =>
    view = new LL.Views.InfluenceIncreaseFull(model: influence)
    $(@el).find('.none').remove()
    $(@el).append($(view.render().el))