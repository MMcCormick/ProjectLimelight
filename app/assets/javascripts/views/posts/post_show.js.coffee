class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'content-tile'

  initialize: ->
    @friendResponsesCollection = new LL.Collections.PostFriendResponses()
    @publicResponsesCollection = new LL.Collections.PostPublicResponses()
    @friendResponses = new LL.Views.PostShowResponses(collection: @friendResponsesCollection)
    @publicResponses = new LL.Views.PostShowResponses(collection: @publicResponsesCollection)
    @publicResponses.post = @model
    @loaded = null

  render: =>
    $(@el).html(@template(post: @model))
    console.log(@model.get('topic_mentions'))


    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    $(@el).append(@friendResponses.el)
    $(@el).append(@publicResponses.el)

    view = new LL.Views.PostForm()
    view.placeholder_text = "Talk about this #{@model.get('type')}..."
    $(@el).find('.talk').html(view.render().el)
    view.model.set('parent_id', @model.get('_id'))
    $(view.el).find('.icons').remove()

    unless @loaded

      @friendResponsesCollection.fetch({data: {id: @model.get('id')}})
      @publicResponsesCollection.fetch({data: {id: @model.get('id')}})

    @loaded = true

    if LL.App.Feed
      $(@el).addClass('modal')

    @