window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    @App =  new LL.Views.App()
    @Main = new LL.Views.Main()
    @Header = new LL.Views.Header()

    @Router = new LL.Router()
    Backbone.history.start(pushState: true)

jQuery ->

  # Start up Backbone
  LL.init()

  $('[rel="tooltip"]').tooltip()