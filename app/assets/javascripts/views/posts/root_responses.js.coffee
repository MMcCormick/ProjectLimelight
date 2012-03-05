class LL.Views.RootResponses extends Backbone.View
  template: JST['posts/root_responses']
  tagName: 'div'
  className: 'responses'

  render: ->
    $(@el).html(@template())
    for post in @model
      @appendResponse(post)
    @

  appendResponse: (post) =>
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@.el).prepend(response_view.render().el)
    @