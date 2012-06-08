class LL.Views.Modal extends Backbone.View
  className: 'll-modal'

  events:
    "click": "navBack"
    "click .close": "navBack"

  initialize: ->
    self = @

    @screens = {}
    @activeScreen = null
    @render()

  render: =>
    $('body').append($(@el).hide())

  hide: =>
    $(@el).fadeOut(250)

  show: =>
    if @activeScreen
      $(@el).fadeIn(250).html(@activeScreen.render().el)

  get: (id) =>
    @screens[id]

  add: (id, screen) =>
    @screens[id] = screen
    @

  setActive: (id) =>
    @activeScreen = @get(id)
    @

  navBack: (e) =>
    if $(e.target).hasClass('ll-modal')
      if @activeScreen.hasNoUrl
        @hide()
      else
        history.back()
