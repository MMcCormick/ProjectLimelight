class LL.Views.RootPost extends Backbone.View
  template: JST['posts/root_post']
  tagName: 'li'
  className: 'tile'

  events:
    "click .talk": "loadPostForm"
    "click .root h2, .root img, .talking": "postShow"

  initialize: ->

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

    if @model.get('responses') && @model.get('responses').length > 0
      responses_view = new LL.Views.RootResponses(model: @model.get('responses'), root: @model.get('root'))
      $(@el).append(responses_view.render().el)

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.render().el
    view.preview.setResponse(@model.get('root'))
    $(view.el).find('.icons').remove()

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)