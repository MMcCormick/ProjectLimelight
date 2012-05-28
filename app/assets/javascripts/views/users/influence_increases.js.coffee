class LL.Views.InfluenceIncreases extends Backbone.View
  template: JST['users/influence_increases']
  tagName: 'div'
  className: 'section'
  id: 'sidebar-influences'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    $(@el).html(@template())

    self = @

    if @collection.models.length == 0
      $(@el).find('ul').html('<li class="none">This bar updates as you gain influence in topics</li>')

    for influence in @collection.models
      @appendInfluence(influence)

    channel = LL.App.get_subscription(@model.get('id'))
    unless channel
      channel = LL.App.subscribe(@model.get('id'))

    unless LL.App.get_event_subscription(@model.get('id'), 'influence_change')
      channel.bind 'influence_change', (data) ->
        $(self.el).oneTime 1500, 'influence', ->
          influence = new LL.Models.InfluenceIncrease(data)
          influence.set('topic', new LL.Models.Topic(influence.get('topic')))
          self.prependInfluence(influence, true)

      LL.App.subscribe_event(@model.get('id'), 'influence_change')

    @

  appendInfluence: (influence) =>
    view = new LL.Views.InfluenceIncrease(model: influence)
    $(@el).find('.none').remove()
    $(@el).find('ul').append($(view.render().el).fadeIn(500))

  prependInfluence: (influence, pulsate=false) =>
    view = new LL.Views.InfluenceIncrease(model: influence)
    $(@el).find('.none').remove()
    $(@el).find('ul').prepend($(view.render().el))

    $(view.el).effect 'slide', {direction: 'left', mode: 'show'}, 500, ->
      if pulsate == true
        $(view.el).effect('pulsate', {times: 1}, 300)