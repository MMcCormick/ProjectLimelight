class LL.Views.TopicList extends Backbone.View
  template: JST['topics/list']
  tagName: 'div'
  className: 'content-tile topic-list'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @appendUser)

    # Always start on page 1
    #@.page = 1

  render: =>
    $(@el).html(@template())
    $('#feed').html(@el)
    $(@el).before("<h2>#{@pageTitle}</h2>")

    if @collection.models.length == 0
      $(@el).find('section').append("<div class='none'>Hmm, there's nothing to show here</div>")
    else
      for topic,i in @collection.models
        @appendUser(topic, i%2)

    @

  appendUser: (topic, odd) =>
    view = new LL.Views.TopicListItem(model: topic)
    view.odd = odd
    $(@el).find('ul').append(view.render().el)

    @