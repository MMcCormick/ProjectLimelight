class LL.Models.InfluencerTopic extends Backbone.Model

  initialize: =>
    if @get('topic')
      @set('topic', LL.App.Topics.findOrCreate(@get('topic').id, @get('topic')))