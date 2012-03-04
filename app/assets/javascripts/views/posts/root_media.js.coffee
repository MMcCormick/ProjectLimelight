class LL.Views.RootMedia extends Backbone.View
  template: JST['posts/root_media']
  tagName: 'div'
  className: 'root'

  initialize: ->

  render: ->
    $(@el).addClass(@model.get('type').toLowerCase()).html(@template(post: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)
    @