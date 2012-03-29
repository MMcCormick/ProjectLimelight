class LL.Views.PageHeader extends Backbone.View
  el: $('#page-header')

  events:
    'click .links a': 'handleLinkClick'

  initialize: ->
    @title = ''
    @links = []
    @showScore = false
    @showFollow = false

  render: =>
    $(@el).show()
    $(@el).find('h1').text(@title)

    if @showScore
      score = new LL.Views.Score(model: @model)
      $(@el).find('.top').append(score.render().el)

    if @showFollow
      if LL.App.current_user != @model
        follow = new LL.Views.FollowButton(model: @model)
        $(@el).find('.top').append(follow.render().el)

    for link in @links
      $(@el).find('.links').append("<li><a class='#{if link.on then 'on' else ''}' href='#{link.url}'>#{link.content}</a></li>")

  handleLinkClick: (e) =>
    if $(e.currentTarget).hasClass('on')
      e.preventDefault()
      return false

    $(e.currentTarget).effect("highlight", {color: '#88B925'}, 300)