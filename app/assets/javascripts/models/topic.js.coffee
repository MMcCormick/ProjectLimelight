class LL.Models.Topic extends Backbone.Model
  url: '/api/topics'

  initialize: ->

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Topics.findOrCreate(resp.id, resp)

  scorePretty: ->
    parseInt @get('score')