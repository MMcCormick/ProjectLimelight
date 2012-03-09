class LL.Views.Main extends Backbone.View
  el: $('body .wrapper .content')

  initialize: ->
    LL.App.UserFeed.on('reset', @renderUserFeed)
    LL.App.LikeFeed.on('reset', @renderLikeFeed)
    LL.App.TopicFeed.on('reset', @renderTopicFeed)
    LL.App.UserFollowers.on('reset', @renderUserFollowers)
    LL.App.UserFollowingUsers.on('reset', @renderUserFollowingUsers)

  renderUserFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
    LL.App.Feed = view
    view.render()
    LL.App.calculateSiteWidth()

  renderLikeFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.LikeFeed)
    LL.App.Feed = view
    view.render()
    LL.App.calculateSiteWidth()

  renderTopicFeed: =>
    view = new LL.Views.PostsFeed(collection: LL.App.TopicFeed)
    LL.App.Feed = view
    view.render()
    LL.App.calculateSiteWidth()

  renderUserFollowers: =>
    view = new LL.Views.UserList(collection: LL.App.UserFollowers)
    LL.App.Feed = view
    view.render()

  renderUserFollowingUsers: =>
    view = new LL.Views.UserList(collection: LL.App.UserFollowingUsers)
    LL.App.Feed = view
    view.render()