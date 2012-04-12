class LL.Views.CommentList extends Backbone.View
  className: 'comment-list unstyled'
  tagName: 'ul'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @appendComment)

    self = @

    # listen to the channel for new comments
    channel = LL.App.get_subscription("#{@model.get('id')}")
    unless channel
      channel = LL.App.subscribe("#{@model.get('id')}")

    unless LL.App.get_event_subscription("#{@model.get('id')}", 'new_comment')
      channel.bind 'new_comment', (data) ->
        comment = new LL.Models.Comment(data)
        self.collection.add(comment)

  render: =>
    if @collection.models.length > 0
      $(@el).html('')
      for comment in @collection.models
        @prependComment(comment)

    @

  prependComment: (comment) =>
    comment_view = new LL.Views.Comment(model: comment)
    $(@el).prepend(comment_view.render().el)
    @

  appendComment: (comment) =>
    comment_view = new LL.Views.Comment(model: comment)
    $(@el).append(comment_view.render().el)
    @