window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    @App =  new LL.Views.App()
    @Main = new LL.Views.Main()

    user_router = new LL.Routers.Users()
    Backbone.history.start(pushState: true)

jQuery ->
  LL.init()