class LL.Views.Comment extends Backbone.View
  template: JST['comments/comment']
  class: 'comment-list'
  tagName: 'li'

  initialize: ->

  render: ->
    $(@el).html(@template(comment: @model))
    @