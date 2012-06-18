class LL.Views.UserTutorial2 extends Backbone.View
  template: JST['users/tutorial_2']
  className: 'tutorial-section'
  id: 'tutorial-2'

  events:
    'click .tlink': 'cancelClick'
    'click .load-more': 'loadMore'

  initialize: ->
    @title= 'Following Topics'
    @topics = new LL.Collections.TopicsByCategory
    @topics.on('reset', @render)
    @count = 0
    @topics.fetch()

  render: =>
    $(@el).html(@template(user: @model, data: @topics.models))
    @target = $(@el).find('.topic-list')

    @appendTopics()

    @parent.updateFollowCount()

    @

  appendTopics: =>
    for item in @topics.models
      for topic in item.get('topics')
        @appendTopic(topic)

  appendTopic: (topic) =>
    follow_button = new LL.Views.FollowButton(model: topic)
    $(".topic-#{topic.get('id')}").append(follow_button.render().el)

  cancelClick: (e) ->
    e.preventDefault()

  loadMore: (e) =>
    $('.load-more').button('loading')
    @page += 1
    @fetchTopics()