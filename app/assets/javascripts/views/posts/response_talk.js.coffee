class LL.Views.ResponseTalk extends Backbone.View
  template: JST['posts/response_talk']
  tagName: 'div'
  className: 'response-talk'

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @comments = new LL.Collections.Comments
    @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
    @comments.add(@model.get('comments'))
    $(@el).find('.comments').html(@comments_view.render().el)

    @