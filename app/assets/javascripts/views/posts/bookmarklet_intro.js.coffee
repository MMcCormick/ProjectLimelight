class LL.Views.BookmarkletIntro extends Backbone.View
  template: JST['posts/bookmarklet_intro']
  tagName: 'div'
  className: 'content-tile'

  initialize: ->

  render: ->
    $(@el).html(@template())

    @