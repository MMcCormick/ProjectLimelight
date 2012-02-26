class LL.Views.TopicSidebarTeaser extends Backbone.View
  template: JST['topics/sidebar_teaser']

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))
    @