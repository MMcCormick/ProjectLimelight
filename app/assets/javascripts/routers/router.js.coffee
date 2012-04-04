class LL.Router extends Backbone.Router
  routes:
    'users/:id/following/topics': 'userFollowingTopics'
    'users/:id/following/users': 'userFollowingUsers'
    'users/:id/followers': 'userFollowers'
    'users/:id/likes': 'likeFeed'
    'users/:id/feed': 'userFeed'
    'users/:id': 'activityFeed'
    'posts/:id': 'postShow'
    'pages/:name': 'staticPage'
    'settings': 'settings'
    'activity': 'activityFeed'
    'likes': 'likeFeed'
    ':id/followers': 'topicFollowers'
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
    else if LL.App.current_user && LL.App.current_user.get('tutorial_step') != 0
      @tutorials()
      return

    @hideModal()

    if id == 0
      user = LL.App.current_user
      @showTipTutorial('user_feed')
    else
      user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    # Only load the feed if it's new
    if LL.App.findScreen('user_feed', id)
      LL.App.showScreen('user_feed', id)
    else
      screen = LL.App.newScreen('user_feed', id)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'feed'
      screen['components'].push(page_header)

      LL.App.renderScreen('user_feed', id)

      feed = new LL.Views.PostsFeed(collection: LL.App.UserFeed)
      feed.channel = "#{user.get('_id')}_realtime"
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.UserFeed.id = id
      LL.App.UserFeed.page = 1
      LL.App.UserFeed.sort_value = 'newest'
      LL.App.UserFeed.fetch({data: {id: id, sort: 'newest'}})

  activityFeed: (id=0) ->

    @hideModal()

    if id == 0
      user = LL.App.current_user
    else
      user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    # Only load the feed if it's new
    if LL.App.findScreen('activity_feed', id)
      LL.App.showScreen('activity_feed', id)
    else
      screen = LL.App.newScreen('activity_feed', id)

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'activity'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('activity_feed', id)

      feed = new LL.Views.PostsFeed(collection: LL.App.ActivityFeed)
      feed.channel = "#{user.get('_id')}_activity"
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.ActivityFeed.id = id
      LL.App.ActivityFeed.page = 1
      LL.App.ActivityFeed.fetch({data: {id: id}})

  likeFeed: (id=0) ->
    if id == 0
      user = LL.App.current_user
    else
      user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('like_feed', id)
      LL.App.showScreen('like_feed', id)
    else
      screen = LL.App.newScreen('like_feed', id)

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'likes'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('like_feed', id)

      feed = new LL.Views.PostsFeed(collection: LL.App.LikeFeed)
      feed.channel = "#{user.get('_id')}_likes"
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.LikeFeed.id = id
      LL.App.LikeFeed.page = 1
      LL.App.LikeFeed.fetch({data: {id: id}})

  settings: ->
    user = LL.App.current_user

    screen = LL.App.newScreen('settings', 0)

    page_header = new LL.Views.UserPageHeader(model: user)
    screen['components'].push(page_header)

    sidebar = LL.App.findSidebar('user', 0)
    unless sidebar
      sidebar = LL.App.createSidebar('user', 0, user)
    screen['sidebar'] = sidebar

    LL.App.renderScreen('settings', 0)

    view = new LL.Views.UserSettings()

  userFollowers: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('user_followers', id)
      LL.App.showScreen('user_followers', id)
    else
      screen = LL.App.newScreen('user_followers', id)

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'followers'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowers()
      feed = new LL.Views.UserList(collection: collection, model: user)
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

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'following_users'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingUsers()
      feed = new LL.Views.UserList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_following_users', id)

      collection.id = id
      collection.page = 1
      collection.fetch({data: {id: id}})

  userFollowingTopics: (id) ->
    user = LL.App.Users.findOrCreate(id, new LL.Models.User($('#this').data('this')))

    if LL.App.findScreen('user_following_topics', id)
      LL.App.showScreen('user_following_topics', id)
    else
      screen = LL.App.newScreen('user_following_topics', id)

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'following_topics'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', id)
      unless sidebar
        sidebar = LL.App.createSidebar('user', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingTopics()
      feed = new LL.Views.TopicList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_following_topics', id)

      collection.id = id
      collection.page = 1
      collection.fetch({data: {id: id}})

  tutorials: ->
    view = new LL.Views.UserTutorial(model: LL.App.current_user)
    view.step = LL.App.current_user.get('tutorial_step')
    $('.wrapper').html(view.render().el)


  #######
  # TOPICS
  #######

  topicFeed: (id) ->
    if id[0] == '?' || id == '_=_'
      @splashPage()
      return

    @hideModal()

    topic = LL.App.Topics.findOrCreate(id, $('#this').data('this'))

    if LL.App.findScreen('topic_feed', id)
      LL.App.showScreen('topic_feed', id)
    else
      screen = LL.App.newScreen('topic_feed', id)

      page_header = new LL.Views.TopicPageHeader(model: topic)
      page_header.page = 'feed'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('topic', id)
      unless sidebar
        sidebar = LL.App.createSidebar('topic', id, topic)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('topic_feed', id)

      feed = new LL.Views.PostsFeed(collection: LL.App.TopicFeed)
      LL.App.Feed = feed
      screen['components'].push(feed)

      LL.App.TopicFeed.id = id
      LL.App.TopicFeed.page = 1
      LL.App.TopicFeed.sort_value = 'newest'
      LL.App.TopicFeed.fetch({data: {id: id, sort: 'newest'}})

  topicFollowers: (id) ->
    topic = LL.App.Topics.findOrCreate(id, $('#this').data('this'))

    if LL.App.findScreen('topic_followers', id)
      LL.App.showScreen('topic_followers', id)
    else
      screen = LL.App.newScreen('topic_followers', id)

      page_header = new LL.Views.TopicPageHeader(model: topic)
      page_header.page = 'followers'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('topic', id)
      unless sidebar
        sidebar = LL.App.createSidebar('topic', id, topic)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.TopicFollowers()
      feed = new LL.Views.UserList(collection: collection, model: topic)
      screen['components'].push(feed)

      LL.App.renderScreen('topic_followers', id)

      collection.id = id
      collection.page = 1
      collection.fetch({data: {id: id}})

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

  showTipTutorial: (type) ->
    switch type
      when 'user_feed'
        unless LL.App.current_user.get('tutorial1_step') == 0
          view = new LL.Views.UserTutorialTips(model: LL.App.current_user)
          view.page = 'user_feed'
          view.render()

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
