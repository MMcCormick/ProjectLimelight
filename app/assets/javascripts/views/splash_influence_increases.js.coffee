class LL.Views.SplashInfluenceIncreases extends Backbone.View
  el: $('.splash-influence')

  initialize: ->
    @collection.on('reset', @render)
    @num = 0

  render: =>
    self = @

    for num in [0...6]
      @num = num
      @appendInfluence(@collection.models[num])

    $(@el).everyTime 10000, 'shift-influence', ->
      self.slideIn()

    @

  appendInfluence: (influence, pulsate=false) =>
    view = new LL.Views.SplashInfluenceIncrease(model: influence)
    $(@el).append($(view.render().el))

    $(view.el).fadeIn(500)

  slideIn: =>
    if @num < @collection.models.length
      view = new LL.Views.SplashInfluenceIncrease(model: @collection.models[@num])
      $(@el).prepend($(view.render().el))

      $(view.el).effect 'slide', {direction: 'right', mode: 'show'}, 1000
      @num += 1