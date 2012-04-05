class LL.Views.RootTalk extends Backbone.View
  template: JST['posts/root_talk']
  tagName: 'div'
  className: 'root talk'

  events:
    'click': 'postShow'

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('.ulink, .score-pts, .like') || $(e.target).is('img')
    LL.Router.navigate("talks/#{@model.get('id')}", trigger: true)