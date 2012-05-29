class LL.Router extends Backbone.Router
  routes:
    'users/:id/following/topics': 'userFollowingTopics'
    'users/:id/following/users': 'userFollowingUsers'
    'users/:id/followers': 'userFollowers'
    'users/:id/likes': 'likeFeed'
    'users/:id/influence': 'userInfluence'
    'users/:id/feed': 'userFeed'
    'users/:id': 'activityFeed'
    'posts/:id': 'postShow'
    'talks/:id': 'talkShow'
    'pages/admin': 'adminHome'
    'topics/new': 'adminManageTopics'
    'crawler_sources': 'adminManageCrawlers'
    'pages/admin/posts/stream': 'adminPostStream'
    'pages/:name': 'staticPage'
    'settings': 'settings'
    'activity': 'activityFeed'
    'likes': 'likeFeed'
    'influence': 'userInfluence'
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
      user = new LL.Models.User($('#this').data('this'))

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

      collection = new LL.Collections.UserFeed
      feed = new LL.Views.PostsFeed(collection: collection)
      feed.default_text = "Streaming posts from #{user.get('following_topics_count')} topics and #{user.get('following_users_count')} users... Follow more things to expand your feed!"
      feed.channel = "#{user.get('id')}_realtime"
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = id
      collection.page = 1
      collection.sort_value = 'newest'
      collection.fetch({data: {id: user.get('id'), sort: 'newest'}})

  activityFeed: (id=0) ->

    @hideModal()

    if id == 0
      user = LL.App.current_user
    else
      user = new LL.Models.User($('#this').data('this'))

    # Only load the feed if it's new
    if LL.App.findScreen('activity_feed', user.get('id'))
      LL.App.showScreen('activity_feed', user.get('id'))
    else
      screen = LL.App.newScreen('activity_feed', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'activity'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('activity_feed', user.get('id'))

      collection = new LL.Collections.ActivityFeed
      feed = new LL.Views.PostsFeed(collection: collection)
      feed.channel = "#{user.get('id')}_activity"
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch({data: {id: user.get('id')}})

  likeFeed: (id=0) ->
    if id == 0
      user = LL.App.current_user
    else
      user = new LL.Models.User($('#this').data('this'))

    if LL.App.findScreen('like_feed', user.get('id'))
      LL.App.showScreen('like_feed', user.get('id'))
    else
      screen = LL.App.newScreen('like_feed', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'likes'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('like_feed', user.get('id'))

      collection = new LL.Collections.LikeFeed
      feed = new LL.Views.PostsFeed(collection: collection)
      feed.channel = "#{user.get('id')}_likes"
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch({data: {id: user.get('id')}})

  userInfluence: (id=0) ->
    if id == 0
      user = LL.App.current_user
    else
      user = new LL.Models.User($('#this').data('this'))

    if LL.App.findScreen('user_influence', user.get('id'))
      LL.App.showScreen('user_influence', user.get('id'))
    else
      screen = LL.App.newScreen('user_influence', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'influence'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      view = new LL.Views.UserInfluence()
      view.user = user
      screen['components'].push(view)

      LL.App.renderScreen('user_influence', user.get('id'))

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
    user = new LL.Models.User($('#this').data('this'))

    if LL.App.findScreen('user_followers', user.get('id'))
      LL.App.showScreen('user_followers', user.get('id'))
    else
      screen = LL.App.newScreen('user_followers', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'followers'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowers()
      feed = new LL.Views.UserList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_followers', user.get('id'))

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch({data: {id: user.get('id')}})

  userFollowingUsers: (id) ->
    user = new LL.Models.User($('#this').data('this'))

    if LL.App.findScreen('user_following_users', user.get('id'))
      LL.App.showScreen('user_following_users', user.get('id'))
    else
      screen = LL.App.newScreen('user_following_users', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'following_users'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingUsers()
      feed = new LL.Views.UserList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_following_users', user.get('id'))

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch({data: {id: user.get('id')}})

  userFollowingTopics: (id) ->
    user = new LL.Models.User($('#this').data('this'))

    if LL.App.findScreen('user_following_topics', user.get('id'))
      LL.App.showScreen('user_following_topics', user.get('id'))
    else
      screen = LL.App.newScreen('user_following_topics', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'following_topics'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingTopics()
      feed = new LL.Views.TopicList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_following_topics', user.get('id'))

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch({data: {id: user.get('id')}})

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

    topic = new LL.Models.Topic($('#this').data('this'))

    if LL.App.findScreen('topic_feed', topic.get('id'))
      LL.App.showScreen('topic_feed', topic.get('id'))
    else
      screen = LL.App.newScreen('topic_feed', topic.get('id'))

      page_header = new LL.Views.TopicPageHeader(model: topic)
      page_header.page = 'feed'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('topic', topic.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('topic', topic.get('id'), topic)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('topic_feed', topic.get('id'))

      collection = new LL.Collections.TopicFeed
      feed = new LL.Views.PostsFeed(collection: collection)
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = topic.get('id')
      collection.page = 1
      collection.sort_value = 'newest'
      collection.fetch({data: {id: topic.get('id'), sort: 'newest'}})

  topicFollowers: (id) ->
    topic = new LL.Models.Topic($('#this').data('this'))

    if LL.App.findScreen('topic_followers', topic.get('id'))
      LL.App.showScreen('topic_followers', topic.get('id'))
    else
      screen = LL.App.newScreen('topic_followers', topic.get('id'))

      page_header = new LL.Views.TopicPageHeader(model: topic)
      page_header.page = 'followers'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('topic', topic.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('topic', topic.get('id'), topic)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.TopicFollowers()
      feed = new LL.Views.UserList(collection: collection, model: topic)
      screen['components'].push(feed)

      LL.App.renderScreen('topic_followers', topic.get('id'))

      collection.id = topic.get('id')
      collection.page = 1
      collection.fetch({data: {id: topic.get('id')}})

  #######
  # POSTS
  #######

  postShow: (id) ->
    if _.include(['Video','Link','Picture'], $('#this').data('type'))
      data = new LL.Models.Post($('#this').data('this'))
    else
      data = {'id':id}

    post = new LL.Models.Post(data)

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


  talkShow: (id) ->
    if $('#this').data('type') == 'Talk'
      post = new LL.Models.Post($('#this').data('this') && $('#this').data('this').id == id)
    else
      post = new LL.Models.Post({'id':id})
      post.fetch(
        {data: {id: post.get('id')}},
        success: (model, response) ->
          model.set(response, {silent: true})
          model.trigger('reset')
      )

    if LL.App.Feed
      if LL.App.Modal.get(id)
        LL.App.Modal.setActive(id).show()
      else
        view = new LL.Views.TalkShow(model: post)
        LL.App.Modal.add(id, view).setActive(id).show()
    else
      view = new LL.Views.TalkShow(model: post)
      $('body').addClass('no-sidebar')
      $('#feed').html(view.el)
      view.render()

  #######
  # ADMIN
  #######

  adminHome: ->

    @hideModal()

    user = LL.App.current_user
    id = user.get('id')

    # Only load the feed if it's new
    if LL.App.findScreen('admin_home', id)
      LL.App.showScreen('admin_home', id)
    else
      screen = LL.App.newScreen('admin_home', id)

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('admin_home', id)

  adminManageTopics: ->

    @hideModal()

    user = LL.App.current_user
    id = user.get('id')

    # Only load the feed if it's new
    if LL.App.findScreen('admin_manage_topics', id)
      LL.App.showScreen('admin_manage_topics', id)
    else
      screen = LL.App.newScreen('admin_manage_topics', id)

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('admin_manage_topics', id)

  adminManageCrawlers: ->

    @hideModal()

    user = LL.App.current_user
    id = user.get('id')

    # Only load the feed if it's new
    if LL.App.findScreen('admin_manage_crawlers', id)
      LL.App.showScreen('admin_manage_crawlers', id)
    else
      screen = LL.App.newScreen('admin_manage_crawlers', id)

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('admin_manage_crawlers', id)

  adminPostStream: ->

    @hideModal()

    user = LL.App.current_user
    id = user.get('id')

    # Only load the feed if it's new
    if LL.App.findScreen('admin_post_stream', id)
      LL.App.showScreen('admin_post_stream', id)
    else
      screen = LL.App.newScreen('admin_post_stream', id)

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('admin_post_stream', id)

      stream = new LL.Collections.PostStream()
      feed = new LL.Views.PostsFeed(collection: stream)
      LL.App.Feed = feed
      screen['components'].push(feed)

      stream.id = id
      stream.page = 1
      stream.sort_value = 'newest'
      stream.fetch()

      $('body').everyTime 5000, ->
        feed.on_add = 'prepend'
        stream.fetch {add: true}

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
        if LL.App.current_user
          view = new LL.Views.PostForm()
          view.placeholder_text = "Suggest something!"
          $('.content-tile section').append(view.render().el)
          view.addTopic($(view.el).find('#post-form-mention1'), "Limelight Feedback", 'foo', "limelight-feedback")
