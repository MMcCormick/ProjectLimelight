class LL.Views.RootResponseTalk extends Backbone.View
  template: JST['posts/root_response_talk']
  tagName: 'div'
  className: 'response-talk'

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @