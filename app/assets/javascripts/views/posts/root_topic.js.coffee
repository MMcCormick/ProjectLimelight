class LL.Views.RootTopic extends Backbone.View
  template: JST['posts/root_topic']
  tagName: 'div'
  className: 'root topic'

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.actions').prepend(follow.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @