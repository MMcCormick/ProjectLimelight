class LL.Views.PostsFeedTopicRibbon extends Backbone.View
  template: JST['posts/topic_ribbon']
  className: 'topic-ribbon'
  tagName: 'ul'

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

    @

  appendItem: (item) =>
    elem = $('<li/>').addClass("ribbon-#{item.get('topic').get('url_pretty')}")
    link = $('<a/>').html("<div>#{item.get('topic').get('name')}</div>")

    if @type == 'activity'
      link.append("<div>#{item.get('count')} Posts</div>")
      if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id')
        link.attr('href', "/activity#{item.get('topic').get('url')}")
      else
        link.attr('href', "#{@model.get('url')}#{item.get('topic').get('url')}")
    else
      link.append("<div>#{item.get('count')} Likes</div>")
      if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id')
        link.attr('href', "/likes#{item.get('topic').get('url')}")
      else
        link.attr('href', "#{@model.get('url')}/likes#{item.get('topic').get('url')}")

    $(@el).append(elem.html(link))

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