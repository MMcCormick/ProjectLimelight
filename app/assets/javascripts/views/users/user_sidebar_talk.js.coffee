class LL.Views.UserSidebarTalk extends Backbone.View
  template: JST['users/sidebar_talk']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @