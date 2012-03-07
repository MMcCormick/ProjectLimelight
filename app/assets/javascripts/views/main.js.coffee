class LL.Views.Main extends Backbone.View
  el: $('body .wrapper .content')

  initialize: ->
    LL.App.UserFeed.on('reset', @renderUserFeed)
    LL.App.LikeFeed.on('reset', @renderLikeFeed)
    LL.App.TopicFeed.on('reset', @renderTopicFeed)

  renderUserFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
    LL.App.Feed = view
    view.render()

  renderLikeFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.LikeFeed)
    LL.App.Feed = view
    view.render()

  renderTopicFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.TopicFeed)
    LL.App.Feed = view
    view.render()