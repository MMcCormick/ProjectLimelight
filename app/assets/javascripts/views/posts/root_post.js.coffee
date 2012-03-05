class LL.Views.RootPost extends Backbone.View
  template: JST['posts/root_post']
  tagName: 'li'
  className: 'tile'

  events:
    "click .talk": "loadPostForm"
    "click .root h2, .root img, .talking": "postShow"

  initialize: ->
    @public_responses = null
    @personal_responses = null

    @model.get('root').on('new_response', @renderResponses)

  showEntry: ->
    Backbone.history.navigate("posts/#{@model.get('id')}", true)

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    $(@el).html(@template())

    if @model.get('root')
      $(@el).addClass(@model.get('root').get('type').toLowerCase())
      switch @model.get('root').get('type')
        when 'Topic'
          root_view = new LL.Views.RootTopic(model: @model.get('root'))
        when 'Talk'
          root_view = new LL.Views.RootTalk(model: @model.get('root'))
        else
          root_view = new LL.Views.RootMedia(model: @model.get('root'))

      $(@el).append(root_view.render().el)

    @renderResponses()

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.render().el
    view.preview.setResponse(@model.get('root'))
    $(view.el).find('.icons').remove()

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)

  renderResponses: (post) =>
    if !@personal_responses
      personal_responses_view = new LL.Views.RootResponses(model: @model)
      personal_responses_view.type = 'personal'
      personal_responses_view.target = $(@el)
      @personal_responses = personal_responses_view

    @personal_responses.render()

    if !@public_responses
      public_responses_view = new LL.Views.RootResponses(model: @model)
      public_responses_view.type = 'public'
      public_responses_view.target = $(@el)
      console.log public_responses_view
      @public_responses = public_responses_view

    @public_responses.render()