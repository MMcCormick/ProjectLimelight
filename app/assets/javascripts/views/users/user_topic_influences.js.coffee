class LL.Views.UserTopicInfluences extends Backbone.View
  template: JST['users/feed_topic_influences']
  id: 'user-topic-influences'
  tagName: 'ul'
  className: 'unstyled'

  initialize: ->

  render: =>
    $(@el).html(@template())

    @