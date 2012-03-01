class LL.Views.TopicSidebarNav extends Backbone.View
  template: JST['topics/sidebar_nav']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    @