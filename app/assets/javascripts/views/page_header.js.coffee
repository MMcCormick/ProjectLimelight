class LL.Views.PageHeader extends Backbone.View
  el: $('#page-header')

  events:
    'click .links a': 'handleLinkClick'
    'click .sorting li': 'handleSort'

  initialize: ->
    @title = ''
    @links = []
    @showScore = false
    @showFollow = false
    @showSorting = false

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

    if @showSorting == true
      $(@el).find('.sorting').show()

    for link in @links
      $(@el).find('.links').append("<li><a class='#{if link.on then 'on' else ''}' href='#{link.url}'>#{link.content}</a></li>")

  handleLinkClick: (e) =>
    if $(e.currentTarget).hasClass('on')
      e.preventDefault()
      return false

    $(e.currentTarget).effect("highlight", {color: '#88B925'}, 300)

  handleSort: (e) =>
    return if $(e.currentTarget).hasClass('on')

    $(e.currentTarget).addClass('on').siblings().removeClass('on')

    unless $(e.currentTarget).data('sort') == 'newest'
      LL.App.unsubscribe(LL.App.Feed.channel)

    LL.App.Feed.reset()
    LL.App.Feed.collection.page = 1
    LL.App.Feed.collection.sort_value = $(e.currentTarget).data('sort')
    LL.App.Feed.collection.fetch({data: {id: LL.App.Feed.collection.id, sort: LL.App.Feed.collection.sort_value}})