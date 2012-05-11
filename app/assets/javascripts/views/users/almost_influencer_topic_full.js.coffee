class LL.Views.AlmostInfluencerTopicFull extends Backbone.View
  template: JST['users/almost_influencer_topic_full']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).html(@template(almost_influencer_topic: @model))

    @
