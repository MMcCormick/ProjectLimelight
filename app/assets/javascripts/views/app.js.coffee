class LL.Views.App extends Backbone.View
  el: $('body')

  events:
    'mouseover .tlink': 'startTopicHoverTab'
    'mouseout .tlink': 'stopTopicHoverTab'

  initialize: ->
    self = @

    @model = new LL.Models.App()

    # The currently active feed
    @Feed = null

    # set the global collections
    @Users = new LL.Collections.Users
    @UserFeed = new LL.Collections.UserFeed
    @LikeFeed = new LL.Collections.LikeFeed

    @Posts = new LL.Collections.Posts

    @Topics = new LL.Collections.Topics
    @TopicFeed = new LL.Collections.TopicFeed
    @TopicSuggestions = new LL.Collections.TopicSuggestions

    # The global modal view
    @Modal = new LL.Views.Modal

    # The global screens & sidebars
    @screens = {}
    @sidebars = {}

    # Pusher subscription tracking
    @subscriptions = {}
    @event_subscriptions = {}

    # set the current user
    @current_user = if $('#me').length > 0 then @Users.findOrCreate($('#me').data('user').id, new LL.Models.User($('#me').data('user'))) else null

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).resize ->
      self.calculateSiteWidth()



  newScreen: (name, id) =>
    @screens["#{name}_#{id}"] = {
      'sidebar': null,
      'components': []
    }

  findScreen: (name, id) =>
    @screens["#{name}_#{id}"]

  findSidebar: (type, id) =>
    @sidebars["#{type}_#{id}"]

  createSidebar: (type, id, model) =>
    switch type
      when 'user'
        sidebar = new LL.Views.UserSidebar(model: model)
        @sidebars["#{type}_#{id}"] = sidebar
      when 'topic'
        sidebar = new LL.Views.TopicSidebar(model: model)
        @sidebars["#{type}_#{id}"] = sidebar

  renderScreen: (name, id) =>
    screen = @screens["#{name}_#{id}"]

    if screen['sidebar']
      screen['sidebar'].page = name
      screen['sidebar'].render()

    for component in screen['components']
      component.render()

  showScreen: (name, id) =>
    screen = @screens["#{name}_#{id}"]

    if screen['sidebar']
      $(screen['sidebar'].el).show()

    for component in screen['components']
      $(component.el).show()



  # HANDLE PUSHER SUBSCRIPTIONS
  get_subscription: (id) =>
    @subscriptions[id]

  subscribe: (id) =>
    @subscriptions[id] = pusher.subscribe(id)

  get_event_subscription: (id, event) =>
    @event_subscriptions["#{id}_#{event}"]

  subscribe_event: (id, event) =>
    @event_subscriptions["#{id}_#{event}"] = true



  calculateSiteWidth: =>
    return unless $('#feed > .column').length > 0

    width = $(window).width()

#    if width >= 1475
#      className = 'five'
    if width >= 1235
      className = 'four'
    else if width >= 995
      className = 'three'
    else
      className = 'two'

    unless $('body').hasClass(className)
      $('body').removeClass('two three four five').addClass(className)
      @trigger('rearrange_columns')



  startTopicHoverTab: (e) =>
    $(e.target).oneTime 500, 'topic-hover', ->
      topic = LL.App.Topics.findOrCreate($(e.currentTarget).data('id'))
      view = new LL.Views.TopicHoverTab(model: topic)
      view.target = $(e.target)
      view.render()

  stopTopicHoverTab: (e) =>
    $(e.target).stopTime 'topic-hover'