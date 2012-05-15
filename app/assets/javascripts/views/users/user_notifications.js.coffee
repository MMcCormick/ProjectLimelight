class LL.Views.UserNotifications extends Backbone.View
  template: JST['users/notifications']
  id: 'user-notifications'

  events:
    'click .close': 'togglePanel'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @prependNotification)
    @count = 0

  render: =>

    if ($('#user-notifications').length == 0)
      $(@el).html(@template())
      $('body').append($(@el))

    if @collection.models.length == 0
      $(@el).find('section').append("<div class='none'>Hmm, there's nothing to show here</div>")
    else
      for notification,i in @collection.models
        @appendNotification(notification)

    @showPanel()

    @clearNotifications()

    self = @

    @

  appendNotification: (notification) =>
    view = new LL.Views.UserNotification(model: notification)
    $(@el).find('ul').append($(view.render().el).show())

  prependNotification: (notification) =>
    view = new LL.Views.UserNotification(model: notification)
    $(@el).find('ul').prepend(view.render().el)
    $(view.el).effect 'slide', {direction: 'left', mode: 'show'}, 500

  togglePanel: =>
    if $(@el).is(':visible')
      @hidePanel()
    else
      @showPanel()

  showPanel: =>
    $(@el).show('slide', {direction:'right', easing: 'easeOutExpo'}, 500)
    difference = $('body').width() - ($('#feed').offset().left + $('#feed').width())
    offset = 245 - difference
    if offset > 0
      $('body').animate({left: "-#{offset}px"}, 500, 'easeOutExpo')

  hidePanel: =>
    $(@el).hide('slide', {direction:'right', easing: 'easeOutExpo'}, 500)
    $('body').animate({left: '0px'}, 500, 'easeOutExpo')

  clearNotifications: =>
    if LL.App.current_user.get('unread_notification_count') > 0
      $.ajax
        url: '/api/users'
        type: 'put'
        dataType: 'json'
        data: {'unread_notification_count': 0}
        complete: ->
          LL.App.current_user.set('unread_notification_count', 0)