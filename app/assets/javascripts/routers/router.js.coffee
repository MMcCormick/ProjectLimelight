class LL.Router extends Backbone.Router
  routes:
    '': 'userFeed'
    'users/:id': 'userFeed'
    'posts/:id': 'postShow'

  initialize: ->
    @bind 'all', @_trackPageview

  _trackPageview: ->
    url = Backbone.history.getFragment()
#    _gaq.push(['_trackPageview', "/#{url}"])

  userFeed: (id=0) ->
    @hideModal()

    user = if id == 0 then LL.App.current_user else LL.App.Users.findOrCreate(id)

    # Only load the feed if it's new
    if LL.App.UserFeed.id != id
      sidebar = new LL.Views.UserSidebar(model: user)
      sidebar.render() if id == 0

      LL.App.UserFeed.id = id
      LL.App.UserFeed.page = 1
      LL.App.UserFeed.fetch({data: {id: id}})

  postShow: (id) ->
    post = LL.App.Posts.findOrCreate(id)

    view = new LL.Views.PostShow(model: post)
    view.render()

  hideModal: ->
    $('.modal').remove()