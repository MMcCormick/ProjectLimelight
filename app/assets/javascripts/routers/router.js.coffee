class LL.Router extends Backbone.Router
  routes:
    'users/:id/topics': 'userTopics'
    'users/:id/users': 'userUsers'
    'users/:id/feed': 'userFeed'
    'users/:id/:topic_id': 'activityFeed'
    'users/:id': 'activityFeed'
    'posts/:id': 'postShow'
    'pages/admin': 'adminHome'
    'topics/new': 'adminManageTopics'
    'crawler_sources': 'adminManageCrawlers'
    'pages/admin/topics/duplicates': 'adminTopicDuplicates'
    'pages/admin/posts/stream': 'adminPostStream'
    'pages/admin/users/index': 'userIndex'
    'pages/:name': 'staticPage'
    'contacts/:provider/callback': 'inviteContacts'
    'settings': 'settings'
    'activity/:topic_id': 'myTopicActivity'
    'activity': 'activityFeed'
    'topics': 'userTopics'
    'users': 'userUsers'
    ':id/users': 'topicUsers'
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
      user = new LL.Models.User(current_object)

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
      page_header.page = 'home'
      screen['components'].push(page_header)

      LL.App.renderScreen('user_feed', id)

      collection = new LL.Collections.UserFeed
      feed = new LL.Views.PostsFeed(collection: collection, model: user)
      feed.type = 'user'
      feed.default_text = "Streaming posts from #{user.get('following_topics_count')} topics and #{user.get('following_users_count')} users... Follow more things to expand your feed!"
      feed.channel = "#{user.get('id')}_realtime"
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = id
      collection.page = 1
      collection.sort_value = 'newest'
      collection.fetch({data: {id: user.get('id'), sort: 'newest'}})

  myTopicActivity: (topic_id=0) ->
    @activityFeed(0, topic_id)

  activityFeed: (id=0, topic_id=0) ->
    @hideModal()

    if id == 0
      user = LL.App.current_user
    else
      user = new LL.Models.User(current_object)

    # Only load the feed if it's new
    if LL.App.findScreen('activity_feed', user.get('id')+topic_id)
      LL.App.showScreen('activity_feed', user.get('id')+topic_id)
    else
      screen = LL.App.newScreen('activity_feed', user.get('id')+topic_id)

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'posts'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      LL.App.renderScreen('activity_feed', user.get('id')+topic_id)

      topic_activity_collection = new LL.Collections.UserTopicActivity
      topic_activity_collection.user = user
      topic_activity = new LL.Views.PostsFeedTopicRibbon(collection: topic_activity_collection, model: user)
      topic_activity.active = topic_id
      topic_activity.type = 'activity'
      screen['components'].push(topic_activity)
      topic_activity_collection.fetch(data: {topic_id: topic_id})

      collection = new LL.Collections.ActivityFeed
      feed = new LL.Views.PostsFeed(collection: collection, model: user)
      feed.type = 'user'
      feed.channel = "#{user.get('id')}_activity"
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = user.get('id')
      collection.page = 1
      collection.topic_id = topic_id
      collection.fetch({data: {id: user.get('id'), topic_id: topic_id}})

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
    view.render()

  userUsers: (id) ->
    user = new LL.Models.User(current_object)

    if LL.App.findScreen('user_users', user.get('id'))
      LL.App.showScreen('user_users', user.get('id'))
    else
      screen = LL.App.newScreen('user_users', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'users'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      collection1 = new LL.Collections.UserFollowingUsers()
      feed1 = new LL.Views.UserList(collection: collection1, model: user)
      feed1.pageTitle = "#{user.get('username')} is Following #{user.get('following_users_count')} Users"
      feed1.half = true
      screen['components'].push(feed1)

      collection2 = new LL.Collections.UserFollowers()
      feed2 = new LL.Views.UserList(collection: collection2, model: user)
      feed2.pageTitle = "#{user.get('username')} has #{user.get('followers_count')} Followers"
      feed2.half = true
      screen['components'].push(feed2)

      LL.App.renderScreen('user_users', user.get('id'))

      collection1.id = user.get('id')
      collection1.page = 1
      collection1.fetch({data: {id: user.get('id')}})

      collection2.id = user.get('id')
      collection2.page = 1
      collection2.fetch({data: {id: user.get('id')}})

  userTopics: (id) ->
    user = new LL.Models.User(current_object)

    if LL.App.findScreen('user_following_topics', user.get('id'))
      LL.App.showScreen('user_following_topics', user.get('id'))
    else
      screen = LL.App.newScreen('user_following_topics', user.get('id'))

      page_header = new LL.Views.UserPageHeader(model: user)
      page_header.page = 'topics'
      screen['components'].push(page_header)

      sidebar = LL.App.findSidebar('user', user.get('id'))
      unless sidebar
        sidebar = LL.App.createSidebar('user', user.get('id'), user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UserFollowingTopics()
      feed = new LL.Views.TopicList(collection: collection, model: user)
      feed.pageTitle = "#{user.get('username')} is Following #{user.get('following_topics_count')} Topics"
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

    topic = new LL.Models.Topic(current_object)

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
      feed = new LL.Views.PostsFeed(collection: collection, model: topic)
      feed.type = 'topic'
      LL.App.Feed = feed
      screen['components'].push(feed)

      collection.id = topic.get('id')
      collection.page = 1
      collection.sort_value = 'newest'
      collection.fetch({data: {id: topic.get('id'), sort: 'newest'}})

  topicUsers: (id) ->
    topic = new LL.Models.Topic(current_object)

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
      feed.pageTitle = "#{topic.get('name')} has #{topic.get('followers_count')} Followers"
      screen['components'].push(feed)

      LL.App.renderScreen('topic_followers', topic.get('id'))

      collection.id = topic.get('id')
      collection.page = 1
      collection.fetch({data: {id: topic.get('id')}})

  #######
  # POSTS
  #######

  postShow: (id) ->
    if typeof current_object != 'undefined' && _.include(['Post','Video','Link','Picture'], current_object.type)
      data = current_object
    else
      data = {'id':id}

    post = new LL.Models.Post(data)

    if LL.App.Feed
      if LL.App.Modal.get(id)
        LL.App.Modal.setActive(id).show()
      else
        view = new LL.Views.PostShow(model: post)
        view.render()
        LL.App.Modal.add(id, view).setActive(id).show()
    else
      view = new LL.Views.PostShow(model: post)
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

  adminTopicDuplicates: ->

    @hideModal()

    user = LL.App.current_user
    id = user.get('id')

    # Only load the feed if it's new
    if LL.App.findScreen('admin_topic_duplicates', id)
      LL.App.showScreen('admin_topic_duplicates', id)
    else
      screen = LL.App.newScreen('admin_topic_duplicates', id)

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      duplicates = new LL.Views.TopicDuplicates()
      screen['components'].push(duplicates)

      LL.App.renderScreen('admin_topic_duplicates', id)

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

  userIndex: (id) ->
    user = new LL.Models.User(current_object)

    if LL.App.findScreen('user_index', user.get('id'))
      LL.App.showScreen('user_index', user.get('id'))
    else
      screen = LL.App.newScreen('user_index', user.get('id'))

      sidebar = LL.App.findSidebar('admin', id)
      unless sidebar
        sidebar = LL.App.createSidebar('admin', id, user)
      screen['sidebar'] = sidebar

      collection = new LL.Collections.UsersAll()
      feed = new LL.Views.UserList(collection: collection, model: user)
      screen['components'].push(feed)

      LL.App.renderScreen('user_index', user.get('id'))

      collection.id = user.get('id')
      collection.page = 1
      collection.fetch()

  #######
  # MISC
  #######

  _trackPageview: ->
#    url = Backbone.history.getFragment()
#    _gaq.push(['_trackPageview', "/#{url}"])

  hideModal: ->
    LL.App.Modal.hide()
    $('.modal, .content-tile.modal').remove()

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
        foo = "bar"

  inviteContacts: (provider) ->
    view = new LL.Views.ShowContacts()
    $('body').append(view.render().el)
