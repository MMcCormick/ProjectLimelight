class LL.Views.RootMedia extends Backbone.View
  template: JST['posts/root_media']
  tagName: 'div'
  className: 'root'

  initialize: ->

  render: ->
    $(@el).html(@template(post: @model))
    @