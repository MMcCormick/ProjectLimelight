class LL.Views.TopicSidebarAliases extends Backbone.View
  template: JST['topics/sidebar_aliases']
  tagName: 'div'
  className: 'section'

  render: ->
    $(@el).html(@template(topic: @model))

    @