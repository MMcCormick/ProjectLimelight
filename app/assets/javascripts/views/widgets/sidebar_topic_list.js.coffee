class LL.Views.SidebarTopicList extends Backbone.View
  template: JST['widgets/sidebar_topic_list']
  className: 'section'

  events:
    'click .load-more': 'loadMore'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @appendTopic)

  render: =>
    $(@el).html(@template(title: @title))

    if @collection.models.length == 0
      $(@el).find('.load-more').remove()

    for topic in @collection.models
      @appendTopic(topic)

    @

  loadMore: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    @collection.fetchNextPage()
    $(@el).find('.load-more').addClass('disabled', 100)

  appendTopic: (topic) =>
    $(@el).find('.loading,.none').remove()
    $(@el).find('.load-more').removeClass('disabled', 100)
    $(@el).find('ul').append("<li><a class='tlink' data-id='#{topic.get('id')}' href='#{topic.get('url')}'>#{topic.get('name')}</a></li>")