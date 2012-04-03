class LL.Views.UserHeaderNav extends Backbone.View
  template: JST['users/header_nav']
  id: 'header-user-nav'
  className: 'dropdown'

  events:
    'click .notifications': 'showNotifications'

  initialize: ->
    @notifications = null

  render: =>
    $(@el).html(@template(user: @model))

    # only if the user is signed in
    if @model
      score = new LL.Views.Score(model: @model)
      $(@el).find('.numbers').append(score.render().el)
    @

  showNotifications: =>
    if @notifications
      $(@notifications.el).toggle('slide', {direction:'right', easing: 'easeOutExpo'}, 500)
    else
      collection = LL.App.Notifications
      @notifications = new LL.Views.UserNotifications(collection: collection)
      collection.fetch()