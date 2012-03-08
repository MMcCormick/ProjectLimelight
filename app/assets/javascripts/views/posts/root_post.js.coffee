class LL.Views.RootPost extends Backbone.View
  template: JST['posts/root_post']
  tagName: 'li'
  className: 'tile'

  events:
    "click .talk-form": "loadPostForm"
    "click .root .img, .talking, .title": "postShow"

  initialize: ->
    @public_responses = null
    @personal_responses = null

    @model.get('root').on('new_response', @renderResponses)

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
    view.modal = true
    view.render().el
    view.preview.setResponse(@model.get('root'))
    $(view.el).find('.icons').remove()

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)

  renderResponses: (post) =>
    if !@like_responses
      like_responses_view = new LL.Views.RootResponses(model: @model)
      like_responses_view.type = 'like'
      like_responses_view.target = $(@el)
      @like_responses = like_responses_view

    @like_responses.render()

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
      @public_responses = public_responses_view

    @public_responses.render()
