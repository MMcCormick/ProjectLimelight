class LL.Views.Main extends Backbone.View
  el: $('#page_inside')

  initialize: ->
    LL.App.UserFeed.on('reset', @renderFeed)

  renderFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
    view.render()