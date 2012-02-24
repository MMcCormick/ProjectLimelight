class LL.Views.RootTopic extends Backbone.View
  template: JST['posts/root_topic']
  tagName: 'div'
  className: 'root topic'

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))
    @