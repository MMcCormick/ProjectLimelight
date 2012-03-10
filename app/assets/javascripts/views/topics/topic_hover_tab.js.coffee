class LL.Views.TopicHoverTab extends Backbone.View
  template: JST['topics/hover_tab']
  className: 'hover-tab topic-hover-tab'

  events:
    'mouseout': 'hideHover'
    'mouseover': 'stopHideHover'

  initialize: ->
    @model.on('change', @render)

  render: =>
    $(@el).html(@template(topic: @model)).hide()
    $(@el).css(
      top: @target.offset().top+40
      left: @target.offset().left
    )
    $('body').append($(@el))
    $(@el).fadeIn(300)
    @

  hideHover: =>
    self = @
    $(@el).oneTime 300, 'hover-hide', ->
      $(self.el).fadeOut(150)

  stopHideHover: =>
    $(@el).stopTime 'hover-hide'