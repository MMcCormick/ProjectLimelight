class LL.Views.UserTutorial2 extends Backbone.View
  template: JST['users/tutorial_2']
  className: 'tutorial-section'
  id: 'tutorial-2'

  events:
    'click .tlink': 'cancelClick'
    'click .load-more': 'loadMore'

  initialize: ->
    @title= 'Following Topics'
    @topics = new LL.Collections.TopicList
    @topics.on('reset', @appendTopics)
    @topics.on('add', @appendTopic)
    @count = 0
    @page = 1
    @fetchTopics()
    @loaded = false

  render: ->
    $(@el).html(@template(user: @model))
    @target = $(@el).find('.topic-list')

    @appendTopics()

    @parent.updateFollowCount()

    @

  appendTopics: =>
    for topic in @topics.models
      @appendTopic(topic)

  appendTopic: (topic) =>
    $('.load-more').button('reset')

    @odd = @count%2
    @count += 1
    view = new LL.Views.TopicListItem(model: topic)
    view.odd = @odd

    if @target
      @target.append(view.render().el)

  cancelClick: (e) ->
    e.preventDefault()

  fetchTopics: =>
    @topics.fetch({data: {sort: ['score', 'desc'], limit: 10, page: @page}})

  loadMore: (e) =>
    $('.load-more').button('loading')
    @page += 1
    @fetchTopics()