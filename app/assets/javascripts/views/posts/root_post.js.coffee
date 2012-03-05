class LL.Views.RootPost extends Backbone.View
  template: JST['posts/root_post']
  tagName: 'li'
  className: 'tile'

  events:
    "click .talk-form": "loadPostForm"
    "click .root h2, .root img, .talking": "postShow"

  initialize: ->
    @public_responses = null
    @personal_responses = null

    @model.get('root').on('new_response', @appendResponse)

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

    if @model.get('personal_responses') && @model.get('personal_responses').length > 0
      personal_responses_view = new LL.Views.RootResponses(model: @model.get('personal_responses'))
      $(@el).append(personal_responses_view.render().el)
      @personal_responses = personal_responses_view

    if @model.get('public_responses') && @model.get('public_responses').length > 0
      public_responses_view = new LL.Views.RootResponses(model: @model.get('public_responses'))
      $(@el).append(public_responses_view.render().el)
      @public_responses = public_responses_view

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.render().el
    view.preview.setResponse(@model.get('root'))
    $(view.el).find('.icons').remove()

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)

  appendResponse: (post) =>
    if LL.App.current_user.get('_id') == post.get('user')._id || LL.App.current_user.following(post.get('user')._id)
      unless @personal_responses
        personal_responses_view = new LL.Views.RootResponses(model: [])
        $(@el).find('.root').after(personal_responses_view.render().el)
        @personal_responses = personal_responses_view
      @personal_responses.appendResponse(post)

    else
      unless @public_responses
        public_responses_view = new LL.Views.RootResponses(model: [])
        $(@el).append(public_responses_view.render().el)
        @public_responses = public_responses_view
      @public_responses.appendResponse(post)
