class LL.Router extends Backbone.Router
  routes:
    'users/:id/following/topics': 'userFollowingTopics'
    'users/:id/following/users': 'userFollowingUsers'
    'users/:id/followers': 'userFollowers'
    'users/:id/likes': 'likeFeed'
    'users/:id': 'userFeed'
    'posts/:id': 'postShow'
    'pages/:name': 'staticPage'
    ':id': 'topicFeed'
    '': 'userFeed'

  initialize: ->
    @bind 'all', @_trackPageview

  #######
  # USERS
  #######

  userFeed: (id=0) ->
    if id == 0 && !LL.App.current_user
      @splashPage()
      return

    @hideModal()

    user = if id == 0 then LL.App.current_user else LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    # Only load the feed if it's new
    if LL.App.findScreen('user_feed', id)
      LL.App.showScreen('user_feed', id)
    else
      screen = LL.App.newScreen('user_feed', id)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      feed_header = new LL.Views.UserFeedHeader(model: user)
      screen['components'].push(feed_header)

      feed = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.renderScreen('user_feed', id)

      LL.App.UserFeed.id = id
      LL.App.UserFeed.page = 1
      LL.App.UserFeed.fetch({data: {id: id}})

  likeFeed: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('like_feed', id)
      LL.App.showScreen('like_feed', id)
    else
      screen = LL.App.newScreen('like_feed', id)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      feed_header = new LL.Views.UserLikeHeader(model: user)
      screen['components'].push(feed_header)

      feed = new LL.Views.PostsFeed(collection: LL.App.LikeFeed)
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.renderScreen('like_feed', id)

      LL.App.LikeFeed.id = id
      LL.App.LikeFeed.page = 1
      LL.App.LikeFeed.fetch({data: {id: id}})

  userFollowers: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('user_followers', id)
      LL.App.showScreen('user_followers', id)
    else
      screen = LL.App.newScreen('user_followers', id)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowers()
      feed = new LL.Views.UserList(collection: collection, model: user)
      feed.pageTitle = "#{user.get('username')}'s Followers"
      screen['components'].push(feed)

      LL.App.renderScreen('user_followers', id)

      collection.id = id
      collection.page = 1
      collection.fetch({data: {id: id}})

  userFollowingUsers: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('user_following_users', id)
      LL.App.showScreen('user_following_users', id)
    else
      screen = LL.App.newScreen('user_following_users', id)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingUsers()
      feed = new LL.Views.UserList(collection: collection, model: user)
      feed.pageTitle = "Users #{user.get('username')} is Following"
      screen['components'].push(feed)

      LL.App.renderScreen('user_following_users', id)

      collection.id = id
      collection.page = 1
      collection.fetch({data: {id: id}})

  #######
  # TOPICS
  #######

  topicFeed: (id) ->
    @hideModal()

    topic = LL.App.Topics.findOrCreate(id, new LL.Models.Topic($('#this').data('this')))

    if LL.App.findScreen('topic_feed', id)
      LL.App.showScreen('topic_feed', id)
    else
      screen = LL.App.newScreen('topic_feed', id)

      sidebar = LL.App.findSidebar('topic', id)
      unless sidebar
        sidebar = LL.App.createSidebar('topic', id, topic)
      screen['sidebar'] = sidebar

      feed = new LL.Views.PostsFeed(collection: LL.App.TopicFeed)
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.renderScreen('topic_feed', id)

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

  splashPage: ->
    view = new LL.Views.SplashPage()
    $('body').prepend(view.render().el)

  staticPage: (name) ->
    sidebar = new LL.Views.StaticPageSidebar()
    sidebar.page = name
    sidebar.render()
    switch name
      when "about"
        foo = "bar"
      when "contact"
        foo = "bar"
      when "help"
        view = new LL.Views.PostForm()
        view.placeholder_text = "Suggest something!"
        $('.content-tile section').append(view.render().el)
        view.addTopic($(view.el).find('#post-form-mention1'), "Limelight Feedback", 'foo', "limelight-feedback")
