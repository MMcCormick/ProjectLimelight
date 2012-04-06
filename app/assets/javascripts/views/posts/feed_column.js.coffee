class LL.Views.FeedColumn extends Backbone.View
  tagName: 'ul'
  className: 'column unstyled'

  initialize: ->
    @height = 0

  appendPost: (view) ->
    $(@el).append(view.render().el)
    @height = $(@el).height()

  prependPost: (view) ->
    $(view.render().el).css({'position':'absolute','visibility':'hidden','display':'block'})
    $(@el).prepend(view.el)

    setTimeout ->
      height = $(view.el).outerHeight()
      marginTop = -1 * (40 + height + parseInt($(view.el).css('margin-bottom')))
      $(view.el).css({'margin-top':marginTop,'position':'relative','visibility':'visible'})

      $(view.el).animate {'margin-top': 0}, 1000, 'easeOutExpo', ->
        @height = $(@el).height()

    , 2000