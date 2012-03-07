class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'content-tile'

  initialize: ->
    @model.on('change', @render)
    @friendResponses = new LL.Views.PostShowResponses(collection: LL.PostFriendResponses)
    @publicResponses = new LL.Views.PostShowResponses(collection: LL.PostPublicResponses)

  render: =>
    $(@el).html(@template(post: @model))
    $(@el).append(@friendResponses.render().el)
    $(@el).append(@publicResponses.render().el)

    if LL.App.Feed
      $(@el).addClass('modal')

    console.log @model
    @