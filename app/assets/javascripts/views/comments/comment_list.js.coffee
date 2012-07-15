class LL.Views.CommentList extends Backbone.View
  template: JST['comments/comment_list']
  className: 'comment-list'
  tagName: 'div'

  initialize: ->
    @model.on('reset_comments', @render)
    @model.on('new_comment', @appendComment)
    self = @

  render: =>
    $(@el).html(@template())

    if @model.get('comments') && @model.get('comments').length > 0
      $(@el).fadeIn(200)
      for comment in @model.get('comments')
        @prependComment(comment)

    @

  prependComment: (comment) =>
    return unless comment

    comment_view = new LL.Views.Comment(model: comment)
    $(@el).find('ul').prepend(comment_view.render().el)

    $(@el).find('li').removeClass('first')
    $(@el).find('li:first').addClass('first')

    if $(@el).parents('.tile:first').length > 0
      $('#feed').isotope('shiftColumnOfItem', $(@el).parents('.tile:first').get(0))

    @

  appendComment: (comment) =>
    return unless comment

    unless $(@el).is(':visible')
      $(@el).fadeIn(200)

    comment_view = new LL.Views.Comment(model: comment)
    $(@el).find('ul').append(comment_view.render().el)

    $(@el).find('li').removeClass('first')
    $(@el).find('li:first').addClass('first')

    if $(@el).parents('.tile:first').length > 0
      $('#feed').isotope('shiftColumnOfItem', $(@el).parents('.tile:first').get(0))

    @