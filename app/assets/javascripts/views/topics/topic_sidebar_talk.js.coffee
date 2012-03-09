class LL.Views.TopicSidebarTalk extends Backbone.View
  template: JST['widgets/sidebar_talk']
  tagName: 'section'
  className: 'sidebar-talk-form'

  events:
    'click input': 'loadPostForm'

  initialize: ->

  render: ->
    placeholder = "Talk about #{@model.get('name')}!"
    $(@el).html(@template(user: @model, placeholder: placeholder))
    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.modal = true
    view.placeholder_text = "Talk about #{@model.get('name')}..."
    view.render().el
    view.addTopic($(view.el).find('#post-form-mention1'), @model.get('name'), @model.get('_id'), @model.get('id'))
    setTimeout ->
      view.focusTalk()
    , 500