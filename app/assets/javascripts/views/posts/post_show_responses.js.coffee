class LL.Views.PostShowResponses extends Backbone.View
  tagName: 'section'
  className: 'hide post-responses'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    if @collection.models.length > 0
      if @collection.constructor.name == 'PostFriendResponses'
        $(@el).addClass('friend-responses').prepend('<h3>Friends Talking</h3>')
      else
        $(@el).addClass('public-responses').prepend("<h3>Other People Talking</h3>")

      for post in @collection.models
        @appendResponse(post)

      $(@el).fadeIn(200)
    @

  appendResponse: (post) =>
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@el).append(response_view.render().el)
    @