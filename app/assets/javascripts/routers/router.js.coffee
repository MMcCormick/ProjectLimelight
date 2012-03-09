class LL.Router extends Backbone.Router
  routes:
    '': 'userFeed'
    ':id': 'topicFeed'
    'users/:id/likes': 'likeFeed'
    'users/:id': 'userFeed'
    'posts/:id': 'postShow'

  initialize: ->
    @bind 'all', @_trackPageview

  _trackPageview: ->
    url = Backbone.history.getFragment()
#    _gaq.push(['_trackPageview', "/#{url}"])

  userFeed: (id=0) ->
    return unless LL.App.current_user

    @hideModal()

    user = if id == 0 then LL.App.current_user else LL.App.Users.findOrCreate(id)

    # Only load the feed if it's new
    if LL.App.UserFeed.id != id
      sidebar = new LL.Views.UserSidebar(model: user)
      sidebar.page = 'feed'
      sidebar.render() if id == 0

      feed_header = new LL.Views.UserFeedHeader(model: user)
      feed_header.render() if id == 0

      LL.App.UserFeed.id = id
      LL.App.UserFeed.page = 1
      LL.App.UserFeed.fetch({data: {id: id}})

  likeFeed: (id) ->
    return unless LL.App.current_user

    @hideModal()

    user = LL.App.Users.findOrCreate(id)

    # Only load the feed if it's new
    if LL.App.LikeFeed.id != id
      sidebar = new LL.Views.UserSidebar(model: user)
      sidebar.page = 'likes'
      sidebar.render() if id == LL.App.current_user.get('id')

      feed_header = new LL.Views.UserLikeHeader(model: user)
      feed_header.render() if id == LL.App.current_user.get('id')

      LL.App.LikeFeed.id = id
      LL.App.LikeFeed.page = 1
      LL.App.LikeFeed.fetch({data: {id: id}})

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

  hideModal: ->
    LL.App.Modal.hide()
    $('.modal, .content-tile').remove()