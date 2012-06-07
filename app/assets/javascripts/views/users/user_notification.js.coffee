class LL.Views.UserNotification extends Backbone.View
  template: JST['users/notification']
  tagName: 'li'

  events:
    'click': 'showRelevant'

  initialize: ->

  render: =>
    console.log @model
    $(@el).html(@template(notification: @model))

    $(@el).addClass(@model.get('type'))

    if @model.get('read') == false
      $(@el).addClass('unread')

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'extended'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').append(prettyTime.render().el)

    @

  showRelevant: (e) =>
    return if $(e.target).is('a')

    if @model.get('type') == 'mention' || @model.get('type') == 'repost' || @model.get('type') == 'comment' || @model.get('type') == 'also'
      LL.App.Feed = true
      LL.Router.navigate("talks/#{@model.get('object').id}", trigger: true)