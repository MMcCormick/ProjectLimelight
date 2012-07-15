class LL.Models.Share extends Backbone.Model
  keepInSync: true
  name: 'share'
  urlRoot: "/api/shares"

  initialize: ->
    mentions = []
    if @get('topic_mentions')
      for mention in @get('topic_mentions')
        mentions.push(new LL.Models.Topic(mention))
    @set('topic_mentions', mentions)