class LL.Views.UserSidebarTalk extends Backbone.View
  template: JST['widgets/sidebar_talk']
  tagName: 'div'
  className: 'section sidebar-talk-form'

  events:
    'click input': 'loadPostForm'

  initialize: ->

  render: ->
    placeholder = if LL.App.current_user == @model then 'Post about something!' else "Post @#{@model.get('username')}!"
    $(@el).html(@template(user: @model, placeholder: placeholder))
    $(@el).updatePolyfill()
    @

  loadPostForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    view = new LL.Views.PostForm()
    view.modal = true
    unless LL.App.current_user == @model
      view.initial_text = "@#{@model.get('username')} "
    view.render()
    setTimeout ->
      view.focusTalk()
    , 500