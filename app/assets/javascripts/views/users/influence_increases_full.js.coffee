class LL.Views.InfluenceIncreasesFull extends Backbone.View
  template: JST['users/influence_increases_full']
  tagName: 'ul'
  id: 'influence-increases-full'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    $(@el).html(@template())

    self = @

    if @collection.models.length == 0
      $(@el).find('ul').html('<li class="none">This bar updates as you gain influence in topics</li>')

    for influence in @collection.models
      @appendInfluence(influence)

    @

  appendInfluence: (influence) =>
    view = new LL.Views.InfluenceIncreaseFull(model: influence)
    $(@el).find('.none').remove()
    $(@el).append($(view.render().el))