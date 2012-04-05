class LL.Views.TalkShow extends Backbone.View
  template: JST['posts/show_talk']
  id: 'talk-show'
  className: 'content-tile'

  initialize: ->
    @loaded = null
    @model.on('change', @render)

  render: =>
    console.log 'foo'

    if @model.get('user')

      $(@el).html(@template(post: @model))

      like = new LL.Views.LikeButton(model: @model)
      $(@el).find('.actions').prepend(like.render().el)

      score = new LL.Views.Score(model: @model)
      $(@el).find('.actions').prepend(score.render().el)

  #    for topic in @model.get('topic_mentions')

      @loaded = true

    else
      $(@el).html('foo')

    if LL.App.Feed
      $(@el).addClass('modal')

    @