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
    console.log('render')

    if @collection.models.length == 0
      $(@el).append("<div class='none'>#{@default_text}</div>")
    else
      $(@el).remove('.none')

      for root_post in @collection.models
        @appendPost(root_post)

      LL.App.calculateSiteWidth()

      setTimeout ->
        if self.isotope_loaded == true
          $(self.el).isotope('destroy')

        $(self.el).isotope
          animationEngine: 'best-available'
          itemSelector: '.tile'
          layoutMode: 'masonryColumnShift'
          masonryColumnShift:
            columnWidth: 340

        self.isotope_loaded = true
      , 100

    if LL.App.current_user
      view = new LL.Views.PostForm()
      view.minimal = true
      view.cancel_buttons = true
      if @type == 'user'
        if @model.get('id') == LL.App.current_user.get('id')
          view.placeholder_text = "What do you want to say?"
        else
          view.placeholder_text = "Talk with @#{@model.get('username')}!"
          view.initial_text = "@#{@model.get('username')} "
      else if @type == 'topic'
        view.placeholder_text = "Post about #{@model.get('name')}!"

      tile = $('<div/>').addClass('tile column-fixed').html(view.render().el)
      $(@el).find('.column:first').prepend(tile)

      if @type == 'topic'
        view.addTopic($(view.el).find('#post-form-mention1'), @model.get('name'), @model.get('id'))

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

  addPost: (root_post) =>
    self = @

    if root_post.get('post').get('type') != 'Post'
      root_id = root_post.get('post').get('id')

      channel = LL.App.get_subscription(root_id)
      unless channel
        channel = LL.App.subscribe(root_id)

      unless LL.App.get_event_subscription(root_id, 'new_response')
        channel.bind 'new_response', (data) ->
          if root_post.get('post')
            post = new LL.Models.Post(data)
            root_post.get('posts').unshift(post)
            root_post.trigger('new_response', post)

        LL.App.subscribe_event(root_id, 'new_response')

  prependPost: (root_post, single=false) =>
    tile = new LL.Views.FeedTile(model: root_post)
    $(@el).prepend($(tile.render().el).addClass('new'))

    if single
      self = @
      setTimeout ->
        $(self.el).isotope('reloadItems').isotope({ sortBy: 'original-order' })
      , 100

    @addPost(root_post)

    @prependNext = false

    @

  appendPost: (root_post, single=false) =>
    if root_post.get('post')
      tile = new LL.Views.FeedTile(model: root_post)

      if single
        self = @
        setTimeout ->
          $(self.el).isotope('insert', $(tile.render().el))
        , 100
      else
        $(@el).append(tile.render().el)

      @addPost(root_post)

    @

  loadMore: (e) =>
    if @collection.page == @page && $(window).scrollTop()+$(window).height() > $(@.el).height()-$(@.el).offset().top
      @.page += 1
      data = {id: @collection.id, p: @.page}

      if @collection.sort_value
        data['sort'] = @collection.sort_value

      if @collection.topic_id
        data['topic_id'] = @collection.topic_id

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