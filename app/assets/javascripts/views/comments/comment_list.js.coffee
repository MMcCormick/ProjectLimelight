class LL.Views.CommentList extends Backbone.View
  template: JST['comments/comment_list']
  className: 'comment-list'
  tagName: 'div'

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
    $(@el).html(@template())
    if @collection.models.length > 0
      $(@el).fadeIn(200)
      for comment in @collection.models
        @prependComment(comment)

    @

  prependComment: (comment) =>
    comment_view = new LL.Views.Comment(model: comment)
    $(@el).find('ul').prepend(comment_view.render().el)

    $(@el).find('li').removeClass('first')
    $(@el).find('li:first').addClass('first')

    $('#feed').isotope('shiftColumnOfItem', $(@el).parents('.tile:first').get(0))

    @

  appendComment: (comment) =>
    unless $(@el).is(':visible')
      $(@el).fadeIn(200)

    comment_view = new LL.Views.Comment(model: comment)
    $(@el).find('ul').append(comment_view.render().el)

    $(@el).find('li').removeClass('first')
    $(@el).find('li:first').addClass('first')

    $('#feed').isotope('shiftColumnOfItem', $(@el).parents('.tile:first').get(0))

    @