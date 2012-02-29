class LL.Views.Main extends Backbone.View
  el: $('body .wrapper .content')

  initialize: ->
    LL.App.UserFeed.on('reset', @renderFeed)

  renderFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
    view.render()