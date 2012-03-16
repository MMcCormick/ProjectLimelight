class LL.Views.RootResponses extends Backbone.View
  template: JST['posts/root_responses']
  tagName: 'div'
  className: 'responses'

  initialize: ->

  render: =>
    if @type == 'personal'
      responses = @model.get('personal_responses')
      className = 'personal-responses'
      if @model.get('personal_talking') == 0
        talking = null
      else
        talking = "Friends Talking"
    else if @type == 'like'
      responses = @model.get('like_responses')
      className = 'like-responses'
      talking = "#{@model.get('like_responses').length} #{(if @model.get('like_responses').length > 1 then 'Likes' else 'Like')}"
    else if @type == 'activity'
      responses = @model.get('activity_responses')
      className = 'activity-responses'
      talking = ""
    else
      responses = @model.get('public_responses')
      className = 'public-responses'
      if @model.get('public_talking') == 0
        talking = ''
      else
        talking = "#{@model.get('public_talking')} #{(if @model.get('public_talking') > 1 then 'People' else 'Person')} Talking"

    $(@el).remove()

    if responses.length > 0
      $(@el).addClass(className).html(@template(talking: talking))

      for post in responses
        @appendResponse(post)

      if @type == 'public'
        @target.append($(@el))
      else
        @target.find('.root').after($(@el))

    @

  appendResponse: (post) =>
    response_view = new LL.Views.RootResponseTalk(model: post)
    $(@el).append(response_view.render().el)
    @