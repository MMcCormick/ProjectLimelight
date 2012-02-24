class LL.Views.ResponseTalk extends Backbone.View
  template: JST['posts/response_talk']
  tagName: 'div'
  className: 'response-talk'

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))
    @