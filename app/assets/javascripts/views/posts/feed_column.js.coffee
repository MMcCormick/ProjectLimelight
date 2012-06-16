class LL.Views.FeedColumn extends Backbone.View
  tagName: 'ul'
  className: 'column unstyled'

  initialize: ->
    @height = 0

  appendPost: (view) ->
    view.column = @

    $(@el).append(view.render().el)

    @height = $(@el).height()

  prependPost: (view) ->
    view.column = @

    self = @
    $(view.el).css({'position':'absolute','visibility':'hidden','display':'block'})

    if $(@el).find('.column-fixed').length == 0
      $(@el).prepend(view.el)
    else
      $(@el).find('.column-fixed').after(view.el)


    setTimeout ->
      height = $(view.el).outerHeight()
      marginTop = -1 * (40 + height + parseInt($(view.el).css('margin-bottom')))
      $(view.el).css({'margin-top':marginTop,'position':'relative','visibility':'visible'})

      $(view.el).animate {'margin-top': 0}, 750, 'easeOutExpo', ->
        self.height = $(self.el).height()

    , 1000