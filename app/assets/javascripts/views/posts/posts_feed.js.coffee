class LL.Views.PostsFeed extends Backbone.View
  template: JST['posts/feed']
  el: $('#feed')

  initialize: ->
    self = @

    @collection.on('reset', @render)
    @collection.on('add', @appendPost)

    # Always start on page 1
    @.page = 1

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).bind 'scroll', (e) ->
      self.loadMore(e)

  render: =>
    $(@el).html(@template())

    # we start with no columns
    @.columns = []
    @.minColumnHeight = 0
    @arrangeColumns()

    for root_post in @collection.models
      @appendPost(root_post)

    # load an extra page if their screen is huge
    @loadMore()

    @

  arrangeColumns: =>
    column_count = Math.floor($('#feed').width() / 240)

    for num in [1..column_count]
      column = new LL.Views.FeedColumn()
      $(@el).append(column.render().el)
      @columns.push(column)

  chooseColumn: =>
    min_height = 9999999999999
    for column in @.columns
      if column.height <= min_height
        chosen = column
        min_height = column.height
    chosen

  appendPost: (root_post) =>
    column = @chooseColumn()
    column.appendPost(new LL.Views.RootPost(model: root_post))

    if root_post.get('root').get('type') != 'Talk'
      root_id = root_post.get('root').get('id')
      channel = pusher.subscribe(root_id)

      channel.bind 'new_response', (data) ->
        root = LL.App.Posts.get(root_id)
        if root
          post = LL.App.Posts.findOrCreate(data.id, new LL.Models.Post(data))
          root.trigger('new_response', post)

    @

  loadMore: (e) ->
    if @collection.page == @.page && @collection.length * @collection.page == 20 * @collection.page && $(window).scrollTop()+$(window).height() > $(@.el).height()-$(@.el).offset().top
      @.page += 1
      @collection.fetch({add: true, data: {id: @collection.id, p: @.page}, success: @incrementPage})

  incrementPage: (collection, response) ->
    if response.length > 0
      collection.page += 1
    else
      collection.page = 0