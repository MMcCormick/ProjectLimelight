class LL.Views.RootResponses extends Backbone.View
  template: JST['posts/root_responses']
  tagName: 'div'
  className: 'responses'

  initialize: ->

  render: =>
    if @type == 'personal'
      responses = @model.get('personal_responses')
      className = 'personal'
    else
      responses = @model.get('public_responses')
      className = 'public'

    $(@el).remove()

    if responses.length > 0
      $(@el).addClass(className).html(@template())

      for post in responses
        @appendResponse(post)

      if @type == 'personal'
        @target.find('.root').after($(@el))
      else
        @target.append($(@el))

    @

  appendResponse: (post) =>
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@.el).prepend(response_view.render().el)
    @