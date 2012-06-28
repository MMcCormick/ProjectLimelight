class LL.Views.PostsFeedTopicRibbon extends Backbone.View
  template: JST['posts/topic_ribbon']
  className: 'topic-ribbon'
  tagName: 'div'

  events:
    'click .show-more': 'toggleOpen'

  initialize: ->
    self = @

    # Always start on page 1
    @page = 1

    @collection.on('reset', @render)

  render: =>
    $(@el).html(@template(type: @type, model: @model))

    for item in @collection.models
      @appendItem(item)

    if @active != 0
      $(@el).find('.on').removeClass('on')
      $(@el).find(".ribbon-#{@active}").addClass('on')

    $('#feed-ribbon').show().append(@el)

    $(@el).find('.topic-ribbon').isotope
      animationEngine: 'best-available'
      itemSelector: 'li'
      layoutMode: 'masonry'

    if @collection.models.length > 5
      $(@el).append("<div class='show-more'>View all topics #{@model.get('username')} is posting in</div>")

    @

  appendItem: (item) =>
    view = new LL.Views.FeedTopicRibbonItem(model: @model)
    view.item = item
    view.type = @type
    $(@el).find('ul').append(view.render().el)

    @

  loadMore: (e) =>
    if @collection.page == @page && $(window).scrollTop()+$(window).height() > $(@.el).height()-$(@.el).offset().top
      @.page += 1
      data = {id: @collection.id, p: @.page}

      if @collection.sort_value
        data['sort'] = @collection.sort_value

      @on_add = 'append'
      @collection.fetch({add: true, data: data, success: @incrementPage})

  incrementPage: (collection, response) =>
    if response.length > 0
      collection.page += 1
    else
      collection.page = 0

  reset: =>
    @page = 1
    @tiles = []
    $(@el).html('')

  toggleOpen: (e) =>
    if $(@el).hasClass('open')
      $(@el).removeClass('open', 200).find('.show-more').text("View all topics #{@model.get('username')} is posting in")
    else
      $(@el).addClass('open', 200).find('.show-more').text("Hide topics #{@model.get('username')} is posting in")