class LL.Views.RootPost extends Backbone.View
  template: JST['posts/root_post']
  tagName: 'li'
  className: 'root-post teaser column'

  events:
    "click .talk-form": "loadPostForm"

  initialize: ->

  showEntry: ->
    Backbone.history.navigate("posts/#{@model.get('id')}", true)

  highlightWinner: ->

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    $(@el).html(@template())

    if @model.get('root')
      switch @model.get('root').get('type')
        when 'Topic'
          root_view = new LL.Views.RootTopic(model: @model.get('root'))
        when 'Talk'
          root_view = new LL.Views.RootTalk(model: @model.get('root'))
        else
          root_view = new LL.Views.RootMedia(model: @model.get('root'))

      $(@el).append(root_view.render().el)

    if @model.get('responses')
      responses_view = new LL.Views.RootResponses(model: @model.get('responses'))
      $(@el).append(responses_view.render().el)

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.render().el
    view.embedly.setResponse(@model.get('root'))