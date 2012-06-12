class LL.Views.TalkShow extends Backbone.View
  template: JST['posts/show_talk']
  id: 'talk-show'
  className: 'content-tile'

  events:
    "click .close": "navBack"

  initialize: ->
    @loaded = null
    @model.on('reset', @render)

  render: =>
    if @model.get('user')
      $(@el).html(@template(post: @model))

      like = new LL.Views.LikeButton(model: @model)
      $(@el).find('.actions').prepend(like.render().el)

      score = new LL.Views.Score(model: @model)
      $(@el).find('.actions').prepend(score.render().el)

      prettyTime = new LL.Views.PrettyTime()
      prettyTime.format = 'extended'
      prettyTime.time = @model.get('created_at')
      $(@el).find('.when').html(prettyTime.render().el)

      topic_section = new LL.Views.TopicSectionList()
      topic_section.topics = @model.get('topic_mentions')
      $(@el).find('.half-sections').append(topic_section.render().el)

      user_section = new LL.Views.UserSectionList()
      user_section.users = @model.get('recent_likes')
      user_section.count = @model.get('likes').length
      $(@el).find('.half-sections').append(user_section.render().el)

      @comments = new LL.Collections.Comments
      @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
      comment_section = $('<div/>').addClass('section').html('<div class="top"><h4>Comments</h4></div><div class="meat"></div>')
      form = new LL.Views.CommentForm(model: @model)
      form.minimal = true
      comment_section.find('.meat').append(form.render().el)
      comment_section.find('.meat').append(@comments_view.render().el)
      $(@el).append(comment_section)
      @comments.fetch({data: {id: @model.get('id')}})

      @loaded = true

    else
      $(@el).html('Loading...')

    if LL.App.Feed || !@loaded
      $(@el).addClass('modal').append('<div class="close">x</div>')

    @

  navBack: (e) =>
    history.back()