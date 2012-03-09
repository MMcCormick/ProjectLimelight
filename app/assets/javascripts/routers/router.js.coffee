class LL.Router extends Backbone.Router
  routes:
    'users/:id/following/topics': 'userFollowingTopics'
    'users/:id/following/users': 'userFollowingUsers'
    'users/:id/followers': 'userFollowers'
    'users/:id/likes': 'likeFeed'
    'users/:id': 'userFeed'
    'posts/:id': 'postShow'
    ':id': 'topicFeed'
    '': 'userFeed'

  initialize: ->
    @bind 'all', @_trackPageview

  #######
  # USERS
  #######

  userFeed: (id=0) ->
    @hideModal()

    user = if id == 0 then LL.App.current_user else LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    # Only load the feed if it's new
    sidebar = new LL.Views.UserSidebar(model: user)
    sidebar.page = 'feed'
    sidebar.render()

    feed_header = new LL.Views.UserFeedHeader(model: user)
    feed_header.render()

    LL.App.UserFeed.id = id
    LL.App.UserFeed.page = 1
    LL.App.UserFeed.fetch({data: {id: id}})

  likeFeed: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    # Only load the feed if it's new
    sidebar = new LL.Views.UserSidebar(model: user)
    sidebar.page = 'likes'
    sidebar.render()

    feed_header = new LL.Views.UserLikeHeader(model: user)
    feed_header.render()

    LL.App.LikeFeed.id = id
    LL.App.LikeFeed.page = 1
    LL.App.LikeFeed.fetch({data: {id: id}})

  userFollowers: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    sidebar = new LL.Views.UserSidebar(model: user)
    sidebar.page = 'followers'
    sidebar.render()

#    feed_header = new LL.Views.UserLikeHeader(model: user)
#    feed_header.render()

    LL.App.UserFollowers.id = id
    LL.App.UserFollowers.page = 1
    LL.App.UserFollowers.fetch({data: {id: id}})

  userFollowingUsers: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    sidebar = new LL.Views.UserSidebar(model: user)
    sidebar.page = 'following_users'
    sidebar.render()

#    feed_header = new LL.Views.UserLikeHeader(model: user)
#    feed_header.render()

    LL.App.UserFollowingUsers.id = id
    LL.App.UserFollowingUsers.page = 1
    LL.App.UserFollowingUsers.fetch({data: {id: id}})

  #######
  # TOPICS
  #######

  topicFeed: (id) ->
    @hideModal()

    topic = LL.App.Topics.findOrCreate(id, new LL.Models.Topic($('#this').data('this')))

    # Only load the feed if it's new
    if LL.App.TopicFeed.id != id
      sidebar = new LL.Views.TopicSidebar(model: topic)
      sidebar.render()

      LL.App.TopicFeed.id = id
      LL.App.TopicFeed.page = 1
      LL.App.TopicFeed.fetch({data: {id: id}})

  #######
  # POSTS
  #######

  postShow: (id) ->
    post = LL.App.Posts.findOrCreate(id, new LL.Models.Post($('#this').data('this')))

    if LL.App.Feed
      if LL.App.Modal.get(id)
        LL.App.Modal.setActive(id).show()
      else
        view = new LL.Views.PostShow(model: post)
        LL.App.Modal.add(id, view).setActive(id).show()
    else
      view = new LL.Views.PostShow(model: post)
      $('body').addClass('no-sidebar')
      $('#feed').html(view.el)

    view.render()

  #######
  # MISC
  #######

  _trackPageview: ->
    url = Backbone.history.getFragment()
#    _gaq.push(['_trackPageview', "/#{url}"])

  hideModal: ->
    LL.App.Modal.hide()
    $('.modal, .content-tile').remove()