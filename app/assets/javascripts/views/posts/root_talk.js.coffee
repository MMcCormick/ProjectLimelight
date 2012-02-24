class LL.Views.RootTalk extends Backbone.View
  template: JST['posts/root_talk']
  tagName: 'div'
  className: 'root talk'

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))
    @