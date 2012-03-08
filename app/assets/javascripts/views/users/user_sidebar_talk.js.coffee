class LL.Views.UserSidebarTalk extends Backbone.View
  template: JST['users/sidebar_talk']
  tagName: 'section'
  className: 'sidebar-talk-form'

  events:
    'click input': 'loadPostForm'

  initialize: ->

  render: ->
    placeholder = if LL.App.current_user == @model then 'Talk about something!' else "Talk with @#{@model.get('username')}!"
    $(@el).html(@template(user: @model, placeholder: placeholder))
    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.modal = true
    unless LL.App.current_user == @model
      view.initial_text = "@#{@model.get('username')} "
    view.render()
    setTimeout ->
      view.focusTalk()
    , 500