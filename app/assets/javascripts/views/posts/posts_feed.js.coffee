class LL.Views.PostsFeed extends Backbone.View
  el: $('#feed')

  initialize: ->
    self = @

    # The pusher channel to listen to
    @channel = null

    # Always start on page 1
    @page = 1

    # Default to no specific topic id
    @topic_id = null

    @isotope_loaded = false
    @default_text = 'There are no items in this feed'
    @type = null
    @on_add = 'append'
    @collection.on('reset', @render)
    @collection.on('add', @handleNewPost)

    LL.App.calculateSiteWidth(true)

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).bind 'scroll', (e) ->
      self.loadMore(e)

  render: =>
    self = @

    $(@el).before("<input type='text' placeholder='Share a URL...' id='post-feed-url' />")

    if @collection.models.length == 0
      $(@el).append("<div class='none'>#{@default_text}</div>")
    else
      $(@el).remove('.none')

      for post in @collection.models
        console.log post
        @appendPost(post)

      LL.App.calculateSiteWidth()

      setTimeout ->
        if self.isotope_loaded == true
          $(self.el).isotope('destroy')

        $(self.el).isotope
          animationEngine: 'best-available'
          itemSelector: '.tile'
          layoutMode: 'masonryColumnShift'
          masonryColumnShift:
            columnWidth: 320

        self.isotope_loaded = true
      , 100

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
          self.prependPost(post, true)

    @

  handleNewPost: (root_post) =>
    if @on_add == 'append'
      @appendPost(root_post, true)
    else
      @prependPost(root_post, true)

  addPost: (post) =>
    self = @

  prependPost: (post, single=false) =>
    tile = new LL.Views.FeedTile(model: post)
    $(@el).prepend($(tile.render().el).addClass('new'))

    if single
      self = @
      setTimeout ->
        $(self.el).isotope('reloadItems').isotope({ sortBy: 'original-order' })
      , 100

    @addPost(post)

    @prependNext = false

    @

  appendPost: (post, single=false) =>
    tile = new LL.Views.FeedTile(model: post)

    if single
      self = @
      setTimeout ->
        $(self.el).isotope('insert', $(tile.render().el))
      , 100
    else
      $(@el).append(tile.render().el)

    @addPost(post)

    @

  loadMore: (e) =>
    if @collection.page == @page && $(window).scrollTop()+$(window).height() > $(@.el).height()-$(@.el).offset().top
      @.page += 1
      data = {id: @collection.id, p: @.page}

      if @collection.sort_value
        data['sort'] = @collection.sort_value

      if @collection.topic_id
        data['topic_id'] = @collection.topic_id

      @showLoading()
      @on_add = 'append'
      @collection.fetch({add: true, data: data, success: @incrementPage})

  incrementPage: (collection, response) =>
    @hideLoading()

    if response.length > 0
      collection.page += 1
    else
      collection.page = 0

  reset: =>
    @page = 1
    @tiles = []
    $(@el).html('')

  showLoading: =>
    $('body').append('<div id="feed-loading">Loading...</div>').fadeIn(500)

  hideLoading: =>
    $('body').find('#feed-loading').remove()