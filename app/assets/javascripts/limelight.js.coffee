window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    new LL.Routers.Users()
    new LL.Routers.Posts()
    Backbone.history.start(pushState: true)

$(document).ready ->
  LL.init()
  main = new LL.Views.Main()