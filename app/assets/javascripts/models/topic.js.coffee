class LL.Models.Topic extends Backbone.Model
  url: '/api/topics'

  initialize: ->

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    if LL.App.Topics.get(resp.id)
      null
    else
      LL.App.Topics.findOrCreate(resp.id, resp)

  scorePretty: ->
    parseInt @get('score')