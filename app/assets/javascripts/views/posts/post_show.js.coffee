class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'modal'

  events:
    "click .bg": "destroyForm"

  initialize: ->
    @friendResponses = new LL.Views.PostShowResponses(collection: LL.PostFriendResponses)
    @publicResponses = new LL.Views.PostShowResponses(collection: LL.PostPublicResponses)

  render: ->
    $(@el).html(@template(post: @model))
    $(@el).append(@friendResponses.render().el)
    $(@el).append(@publicResponses.render().el)

    $('body').append($(@el))

    @

  destroyForm: ->
    history.back()