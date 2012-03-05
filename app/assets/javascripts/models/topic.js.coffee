class LL.Models.Topic extends Backbone.Model
  url: '/api/topics'

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Topics.findOrCreate(resp.id, new LL.Models.Topic(resp))

  scorePretty: ->
    parseInt @get('score')