class LL.Views.UserHeaderNav extends Backbone.View
  template: JST['users/header_nav']
  id: 'header-user-nav'
  className: 'dropdown'

  events:
    'click .notifications': 'showNotifications'
    'click .login': 'showLogin'


  initialize: ->
    @notifications = null
    if @model
      @model.bind('change:unread_notification_count', @updateNotificationCount)

  render: =>
    self = @

    $(@el).html(@template(user: @model))

    if @model
      # listen for notifications
      channel = LL.App.get_subscription("#{self.model.get('id')}_private")
      unless LL.App.get_event_subscription("#{self.model.get('id')}_private", 'new_notification')
        channel.bind 'new_notification', (data) ->
          self.model.set('unread_notification_count', self.model.get('unread_notification_count') + 1)
          if self.notifications
            notification = new LL.Models.Notification(data)
          createGrowl(false, "#{data.triggered_by.username} #{data.sentence}", 'Notification', 'green')

        LL.App.subscribe_event("#{self.model.get('id')}_private", 'new_notification')

    @

  showNotifications: =>
    if @notifications
      @notifications.togglePanel()
    else
      collection = new LL.Collections.UserNotifications
      @notifications = new LL.Views.UserNotifications(collection: collection)
      @notifications.render()
      @notifications.showLoading()
      collection.fetch()

  updateNotificationCount: =>
    $(@el).find('.notifications span').text(@model.get('unread_notification_count')).attr('data-original-title', "#{@model.get('unread_notification_count')} Unread Notifications")
    $(@el).find('.notifications span').removeClass('unread').addClass(if (@model.get('unread_notification_count') > 0) then 'unread' else '')

  showLogin: =>
    LL.LoginBox.showModal()