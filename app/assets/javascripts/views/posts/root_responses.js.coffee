class LL.Views.RootResponses extends Backbone.View
  template: JST['posts/root_responses']
  tagName: 'div'
  className: 'responses'

  initialize: ->

  render: =>
    console.log @model
    if @type == 'personal'
      responses = @model.get('personal_responses')
      className = 'personal'
      if @model.get('personal_talking') == 0
        talking = null
      else
        talking = "#{@model.get('personal_talking')} Friend#{(if @model.get('personal_talking') > 1 then 's' else '')} Talking"
    else
      responses = @model.get('public_responses')
      className = 'public'
      if @model.get('public_talking') == 0
        talking = ''
      else
        talking = "#{@model.get('personal_talking')} #{(if @model.get('personal_talking') > 1 then 'People' else 'Person')} Talking"

    $(@el).remove()

    if responses.length > 0
      $(@el).addClass(className).html(@template(talking: talking))

      for post in responses
        @appendResponse(post)

      if @type == 'personal'
        @target.find('.root').after($(@el))
      else
        @target.append($(@el))

    @

  appendResponse: (post) =>
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@.el).append(response_view.render().el)
    @