class LL.Views.Main extends Backbone.View
  el: $('body .wrapper .content')

  initialize: ->
    LL.App.UserFeed.on('reset', @renderUserFeed)
    LL.App.LikeFeed.on('reset', @renderLikeFeed)
    LL.App.TopicFeed.on('reset', @renderTopicFeed)

  renderUserFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
    view.render()

  renderLikeFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.LikeFeed)
    view.render()

  renderTopicFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.TopicFeed)
    view.render()