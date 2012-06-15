class LL.Models.Topic extends Backbone.Model
  keepInSync: true
  name: 'topic'
  urlRoot: "/api/topics"

  initialize: ->


  scorePretty: ->
    parseInt @get('score')