class LL.Models.Topic extends Backbone.Model
  url: '/api/topics'
  keepInSync: true
  name: 'topic'

  initialize: ->

  scorePretty: ->
    parseInt @get('score')