class LL.Views.App extends Backbone.View
  el: $('body')

  events:
    'mouseover .tlink': 'startTopicHoverTab'
    'mouseout .tlink': 'stopTopicHoverTab'
    'mouseover .ulink': 'startUserHoverTab'
    'mouseout .ulink': 'stopUserHoverTab'

  initialize: ->
    self = @

    @model = new LL.Models.App()

    # The currently active feed
    @Feed = null

    # The global modal view
    @Modal = new LL.Views.Modal

    # The global screens & sidebars
    @activeScreen = null
    @screens = {}
    @sidebars = {}

    # Pusher subscription tracking
    @subscriptions = {}
    @event_subscriptions = {}

    # set the current user
    @current_user = if typeof current_user != 'undefined' then new LL.Models.User(current_user) else null

    # listen to the private user channgel
    if @current_user
      channel = @get_subscription("#{@current_user.get('id')}_private")
      unless channel
        channel = @subscribe("#{@current_user.get('id')}_private")

    console.log 'app'

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).resize ->
      $('body').stopTime 'resize'
      $('body').oneTime 200, 'resize', ->
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
      when 'admin'
        sidebar = new LL.Views.AdminSidebar()
        @sidebars["#{type}_#{id}"] = sidebar

  renderScreen: (name, id) =>
    @hideActiveScreen()

    screen = @screens["#{name}_#{id}"]

    if screen['sidebar']
      screen['sidebar'].page = name
      screen['sidebar'].render()

    for component in screen['components']
      component.render()

    @activeScreen = screen

  showScreen: (name, id) =>
    @hideActiveScreen()

    screen = @screens["#{name}_#{id}"]

    if screen['sidebar']
      $(screen['sidebar'].el).show()

    for component in screen['components']
      $(component.el).show()

    @activeScreen = screen

  hideActiveScreen: =>
    return unless @activeScreen

    if @activeScreen['sidebar']
      $(@activeScreen['sidebar'].el).hide()

    for component in @activeScreen['components']
      $(component.el).hide()

  # HANDLE PUSHER SUBSCRIPTIONS
  get_subscription: (id) =>
    @subscriptions[id]

  subscribe: (id) =>
    @subscriptions[id] = pusher.subscribe(id)

  unsubscribe: (id) =>
    pusher.unsubscribe(id)
    delete @subscriptions[id]

  get_event_subscription: (id, event) =>
    @event_subscriptions["#{id}_#{event}"]

  subscribe_event: (id, event) =>
    @event_subscriptions["#{id}_#{event}"] = true



  calculateSiteWidth: (force=false) =>
    if force == false && $('#feed .tile').length == 0
      return

    width = $(window).width()

#    if width >= 1475
#      className = 'five'
    if width >= 1235
      className = 'three'
    else #if width >= 995
      className = 'two'
#    else
#      className = 'two'

    unless $('body').hasClass(className)
      $('body').removeClass('two three four five').addClass(className)
      $('.qtip').qtip('reposition')
#      $('#feed').isotope('reLayout')



  startTopicHoverTab: (e) =>
    self = @

    $(e.target).oneTime 150, 'topic-hover', ->
      topic = new LL.Models.Topic({'id': $(e.currentTarget).data('id')})
      tab = new LL.Views.TopicHoverTab(model: topic)

      target = $(e.currentTarget).find('h1,h2,h3,h4,h5').first()
      if target.length == 0
        target = $(e.currentTarget)

      tab.setTarget(target)
      tab.render()

  stopTopicHoverTab: (e) =>
    $(e.target).stopTime 'topic-hover'

  startUserHoverTab: (e) =>
    self = @

    $(e.target).oneTime 150, 'user-hover', ->
      user = new LL.Models.User({'id': $(e.currentTarget).data('id')})
      tab = new LL.Views.UserHoverTab(model: user)

      target = $(e.currentTarget).find('h1,h2,h3,h4,h5').first()
      if target.length == 0
        target = $(e.currentTarget)

      tab.setTarget(target)
      tab.render()

  stopUserHoverTab: (e) =>
    $(e.target).stopTime 'user-hover'