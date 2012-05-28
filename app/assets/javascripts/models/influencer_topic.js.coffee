class LL.Models.InfluencerTopic extends Backbone.Model
  keepInSync: true
  name: 'influencer-topic'

  initialize: =>
    if @get('topic')
      @set('topic', new LL.Models.Topic(@get('topic')))