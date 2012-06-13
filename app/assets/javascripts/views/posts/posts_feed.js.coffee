class LL.Views.PostsFeed extends Backbone.View
  el: $('#feed')

  initialize: ->
    self = @

    # The pusher channel to listen to
    @channel = null

    # Always start on page 1
    @page = 1

    # A tile is the backbone view representing one tile on the feed
    @tiles = []
    @columns = []

    @default_text = 'There are no items in this feed'
    @on_add = 'append'
    @collection.on('reset', @render)
    @collection.on('add', @handleNewPost)

    LL.App.calculateSiteWidth(true)

    LL.App.on('rearrange_columns', @rearrangeColumns)

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).bind 'scroll', (e) ->
      self.loadMore(e)

  render: =>
    self = @

    if @collection.models.length == 0
      $(@el).append("<div class='none'>#{@default_text}</div>")
    else
      $(@el).remove('.none')

      # we start with no columns
      @columns = []
      @minColumnHeight = 0
      @arrangeColumns()

      for root_post in @collection.models
        @appendPost(root_post)

      LL.App.calculateSiteWidth()

    # listen to the channel for new posts
    channel = LL.App.get_subscription(@channel)
    unless channel
      channel = LL.App.subscribe(@channel)

    unless LL.App.get_event_subscription(@channel, 'new_post')
      channel.bind 'new_post', (data) ->
        post = self.collection.get(data.id)
        if post
          post.trigger('move_to_top')
        else
          post = new LL.Models.RootPost(data)
          self.collection.add(post, {silent: true})
          self.prependPost(post)

    @

  rearrangeColumns: =>
    @columns = []
    @minColumnHeight = 0
    @arrangeColumns()

    for tile in @tiles
      column = @chooseColumn()
      $(column.el).append(tile.el)
      column.height = $(column.el).height()

  arrangeColumns: =>
    column_count = Math.floor($('#feed').width() / 320)

    for num in [1..column_count]
      column = new LL.Views.FeedColumn()
      $(@el).append(column.render().el)
      $(column.el).addClass('last') if num == column_count
      @columns.unshift(column)

  chooseColumn: =>
    min_height = 9999999999999
    for column in @columns
      if column.height <= min_height
        chosen = column
        min_height = column.height
    chosen

  handleNewPost: (root_post) =>
    if @on_add == 'append'
      @appendPost(root_post)
    else
      @prependPost(root_post)

  addPost: (root_post) =>
    self = @

    if root_post.get('root').get('type') != 'Talk'
      root_id = root_post.get('root').get('id')

      channel = LL.App.get_subscription(root_id)
      unless channel
        channel = LL.App.subscribe(root_id)

      unless LL.App.get_event_subscription(root_id, 'new_response')
        channel.bind 'new_response', (data) ->
          console.log data
          if root_post.get('root')
            post = new LL.Models.Post(data)
            root_post.get('feed_responses').unshift(post)
            console.log 'foo'
            root_post.trigger('new_response', post)

        LL.App.subscribe_event(root_id, 'new_response')

  prependPost: (root_post) =>
    column = @chooseColumn()
    tile = new LL.Views.RootPost(model: root_post)
    @tiles.push tile
    tile.render()
    column.prependPost tile
    $(tile.el).addClass('fade-new').find('.root').animate(backgroundColor: '#FFF', 600000)

    @addPost(root_post)

    @prependNext = false

    @

  appendPost: (root_post) =>
    column = @chooseColumn()
    if root_post.get('root') && root_post.get('root').get("type") != 'Topic'
      tile = new LL.Views.RootPost(model: root_post)
      @tiles.push tile
      column.appendPost tile

      @addPost(root_post)

    @

  loadMore: (e) =>
    if @collection.page == @page && $(window).scrollTop()+$(window).height() > $(@.el).height()-$(@.el).offset().top
      @.page += 1
      data = {id: @collection.id, p: @.page}

      if @collection.sort_value
        data['sort'] = @collection.sort_value

      @on_add = 'append'
      @collection.fetch({add: true, data: data, success: @incrementPage})

  incrementPage: (collection, response) =>
    if response.length > 0
      collection.page += 1
    else
      collection.page = 0

  reset: =>
    @page = 1
    @tiles = []
    $(@el).html('')

  # TODO: Show a loading spinner or something here if we want to after a certain amount of time
  loading: =>