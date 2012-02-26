class LL.Routers.Users extends Backbone.Router
  routes:
    '': 'feed'
    'users/:id': 'feed'

  initialize: ->

  feed: (id=0) ->
    user = if id == 0 then LL.App.current_user else LL.App.Users.findOrCreate(id)

    sidebar = new LL.Views.UserSidebar(model: user)
    sidebar.render() if id == 0

    LL.App.UserFeed.id = id
    LL.App.UserFeed.page = 1
    LL.App.UserFeed.fetch({data: {id: id}})