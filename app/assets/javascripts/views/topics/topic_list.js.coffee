class LL.Views.TopicList extends Backbone.View
  template: JST['topics/list']
  tagName: 'div'
  className: 'content-tile topic-list'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @appendUser)
    @pageTitle = ''

  render: =>
    $(@el).html(@template())
    $('#feed').html(@el)

    if @pageTitle != ''
      $(@el).find('.section').prepend("<div class='top'><h4>#{@pageTitle}</h4></div>")

    if @collection.models.length == 0
      $(@el).find('.section').append("<div class='none'>Hmm, there's nothing to show here</div>")
    else
      for topic,i in @collection.models
        @appendUser(topic, i%2)

    @

  appendUser: (topic, odd) =>
    view = new LL.Views.TopicListItem(model: topic)
    view.odd = odd
    $(@el).find('ul').append(view.render().el)

    @