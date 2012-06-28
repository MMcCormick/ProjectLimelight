class LL.Views.TopicSidebarInfo extends Backbone.View
  template: JST['topics/sidebar_info']
  tagName: 'div'
  className: 'section'

  render: ->
    $(@el).html(@template(topic: @model))

    @