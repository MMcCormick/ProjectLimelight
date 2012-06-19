class LL.Views.RootResponses extends Backbone.View
  template: JST['posts/root_responses']
  tagName: 'div'
  className: 'responses'

  render: =>
    if @type == 'feed'
      responses = @model.get('feed_responses')
    else if @type == 'like'
      responses = @model.get('like_responses')
      className = 'like-responses'
      talking = ""
    else if @type == 'activity'
      responses = @model.get('activity_responses')
      className = 'activity-responses'
      talking = ""

    $(@el).remove()

    if responses.length > 0
      $(@el).html(@template(talking: talking))

      for post in responses
        @appendResponse(post)

    @

  appendResponse: (post) =>
    response_view = new LL.Views.RootTalk(model: post)
    $(@el).append(response_view.render().el)

    @

  prependResponse: (post) =>
    response_view = new LL.Views.RootTalk(model: post)
    $(@el).prepend($(response_view.render().el).hide())
    $(response_view.el).show("slide", { direction: 'left' }, 500)

    @