class LL.Views.FeedColumn extends Backbone.View
  tagName: 'ul'
  className: 'column-temporary'

  initialize: ->
    @height = 0

  appendPost: (view) ->
    $(@el).append(view.render().el)
    @height = $(@el).height()