class LL.Views.TopicSidebarNav extends Backbone.View
  template: JST['topics/sidebar_nav']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.actions').prepend(follow.render().el)

    @