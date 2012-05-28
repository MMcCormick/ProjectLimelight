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
    @screens = {}
    @sidebars = {}

    # Pusher subscription tracking
    @subscriptions = {}
    @event_subscriptions = {}

    # Hover Tabs
    @topic_hover_tabs = []
    @user_hover_tabs = []

    # set the current user
    @current_user = if $('#me').length > 0 then new LL.Models.User($('#me').data('user')) else null

    # listen to the private user channgel
    if @current_user
      channel = @get_subscription("#{@current_user.get('id')}_private")
      unless channel
        channel = @subscribe("#{@current_user.get('id')}_private")

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
      when 'admin'
        sidebar = new LL.Views.AdminSidebar()
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

  unsubscribe: (id) =>
    pusher.unsubscribe(id)
    delete @subscriptions[id]

  get_event_subscription: (id, event) =>
    @event_subscriptions["#{id}_#{event}"]

  subscribe_event: (id, event) =>
    @event_subscriptions["#{id}_#{event}"] = true



  calculateSiteWidth: (force=false) =>
    if force == false && $('#feed > .column').length == 0
      return

    width = $(window).width()

#    if width >= 1475
#      className = 'five'
    if width >= 1235
      className = 'four'
    else #if width >= 995
      className = 'three'
#    else
#      className = 'two'

    unless $('body').hasClass(className)
      $('body').removeClass('two three four five').addClass(className)
      $('.qtip').qtip('reposition')
      @trigger('rearrange_columns')



  startTopicHoverTab: (e) =>
    self = @

    $(e.target).oneTime 1000, 'topic-hover', ->
      id = $(e.currentTarget).data('id')
      return if _.include(self.topic_hover_tabs, id)

      topic = new LL.Models.Topic({'id': id})
      tab = new LL.Views.TopicHoverTab(model: topic)

      target = $(e.currentTarget).find('h1,h2,h3,h4,h5').first()
      if target.length == 0
        target = $(e.currentTarget)

      console.log target

      tab.setTarget(target)
      tab.render()
      self.topic_hover_tabs.push id

  stopTopicHoverTab: (e) =>
    $(e.target).stopTime 'topic-hover'

  startUserHoverTab: (e) =>
    self = @

    $(e.target).oneTime 1000, 'user-hover', ->
      id = $(e.currentTarget).data('id')
      return if _.include(self.user_hover_tabs, id)

      user = new LL.Models.User({'id': id})
      tab = new LL.Views.UserHoverTab(model: user)

      target = $(e.currentTarget).find('h1,h2,h3,h4,h5').first()
      if target.length == 0
        target = $(e.currentTarget)

      tab.setTarget(target)
      tab.render()
      self.user_hover_tabs.push id

  stopUserHoverTab: (e) =>
    $(e.target).stopTime 'user-hover'