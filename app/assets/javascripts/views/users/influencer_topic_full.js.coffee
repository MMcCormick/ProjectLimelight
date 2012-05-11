class LL.Views.InfluencerTopicFull extends Backbone.View
  template: JST['users/influencer_topic_full']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).html(@template(influencer_topic: @model))

    @
