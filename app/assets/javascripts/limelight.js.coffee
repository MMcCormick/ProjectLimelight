window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    @App =  new LL.Views.App()
    @Main = new LL.Views.Main()

    @Router = new LL.Router()
    Backbone.history.start(pushState: true)

jQuery ->
  LL.init()

