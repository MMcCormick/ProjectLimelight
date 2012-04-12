class LL.Views.TalkShow extends Backbone.View
  template: JST['posts/show_talk']
  id: 'talk-show'
  className: 'content-tile'

  initialize: ->
    @loaded = null
    @model.on('change', @render)

  render: =>
    if @model.get('user')

      $(@el).html(@template(post: @model))

      like = new LL.Views.LikeButton(model: @model)
      $(@el).find('.actions').prepend(like.render().el)

      score = new LL.Views.Score(model: @model)
      $(@el).find('.actions').prepend(score.render().el)

  #    for topic in @model.get('topic_mentions')

      @comments = new LL.Collections.Comments
      @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
      comment_section = $('<section/>').html('<h4>Comments</h4>')
      form = new LL.Views.CommentForm(model: @model)
      form.minimal = true
      comment_section.append(form.render().el)
      comment_section.append(@comments_view.render().el)
      $(@el).append(comment_section)
      @comments.fetch({data: {id: @model.get('id')}})

      @loaded = true

    else
      $(@el).html('Loading...')

    if LL.App.Feed
      $(@el).addClass('modal')

    @