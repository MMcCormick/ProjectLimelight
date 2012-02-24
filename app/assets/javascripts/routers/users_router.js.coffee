class LL.Routers.Users extends Backbone.Router
  routes:
    '': 'feed'
    'users/:id': 'feed'

  initialize: ->
    @collection = new LL.Collections.UserFeed()
#    @collection.reset($('#posts-feed').data('posts'))

  feed: (id=0) ->
    @collection.fetch({data: {id: id}})
    @collection.id = id
    @collection.page = 1
    view = new LL.Views.PostsFeed(collection: @collection)
    $('#page_header').after(view.render().el)
