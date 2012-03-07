class LL.Views.PostShowResponses extends Backbone.View
  tagName: 'section'
  className: 'hide'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    if @collection.models.length > 0
      if @collection.constructor.name == 'PostFriendResponses'
        $(@el).prepend('<h2>Friend Responses</h2>')
      else
        $(@el).prepend('<h2>Public Responses</h2>')

      for post in @collection.models
        @appendResponse(post)

      $(@el).fadeIn(200)
    @

  appendResponse: (post) =>
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@el).append(response_view.render().el)
    @