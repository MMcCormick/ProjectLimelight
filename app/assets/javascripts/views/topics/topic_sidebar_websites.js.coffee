class LL.Views.TopicSidebarWebsites extends Backbone.View
  template: JST['topics/sidebar_websites']
  tagName: 'div'
  className: 'section'

  render: ->
    $(@el).html(@template(topic: @model))

    @