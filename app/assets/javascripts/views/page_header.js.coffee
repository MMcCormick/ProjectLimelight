class LL.Views.PageHeader extends Backbone.View
  el: $('#page-header')

  events:
    'click .links a': 'handleLinkClick'
    'click .sorting li': 'handleSort'
    'mouseenter .links a': 'linkEnter'
    'mouseleave .links a': 'linkLeave'

  initialize: ->
    @title = ''
    @subtitle = null
    @links = []
    @showSorting = false

  render: =>
    $(@el).show()
    $(@el).find('h1').text(@title)
    if @subtitle
      $(@el).find('.subtitle').text(@subtitle)

    if @showSorting == true
      $(@el).find('.sorting').show()

    for link in @links
      link_html = $('<li/>').addClass(link.class).html("<a class='#{if link.on then 'on' else ''}' href='#{link.url}'><div class='icon ll-ph-#{link.class} #{if link.on then 'on' else ''}'></div>#{link.content}</a>")
      if link.on
        link_html.find('a').append('<div class="ll-ph-carrot"></div>')
      $(@el).find('.links').append(link_html)

    unless LL.App.current_user
      invite = new LL.Views.RequestInvite()
      $(@el).height(195).prepend(invite.render().el).find('.container').css('padding-top': 80)

  handleLinkClick: (e) =>
    if $(e.currentTarget).hasClass('on')
      e.preventDefault()
      return false

  handleSort: (e) =>
    return if $(e.currentTarget).hasClass('on')

    $(e.currentTarget).addClass('on').siblings().removeClass('on')

    unless $(e.currentTarget).data('sort') == 'newest'
      LL.App.unsubscribe(LL.App.Feed.channel)

    LL.App.Feed.reset()
    LL.App.Feed.collection.page = 1
    LL.App.Feed.collection.sort_value = $(e.currentTarget).data('sort')
    LL.App.Feed.collection.fetch({data: {id: LL.App.Feed.collection.id, sort: LL.App.Feed.collection.sort_value}})

  linkEnter: (e) =>
    $(e.currentTarget).find('.icon').addClass('on')

  linkLeave: (e) =>
    unless $(e.currentTarget).hasClass('on')
      $(e.currentTarget).find('.icon').removeClass('on')