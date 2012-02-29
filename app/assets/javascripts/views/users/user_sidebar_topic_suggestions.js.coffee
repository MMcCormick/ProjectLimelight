class LL.Views.UserSidebarTopicSuggestions extends Backbone.View
  template: JST['users/sidebar_topic_suggestions']
  tagName: 'section'

  initialize: ->
    LL.App.TopicSuggestions.on('reset', @render, @)

  render: ->
    $(@el).html(@template())
    i = 0
    for suggestion in LL.App.TopicSuggestions.models
      if i < 3
        @appendSuggestion(suggestion)
        i++
    @

  appendSuggestion: (suggestion) =>
    view = new LL.Views.TopicSidebarTeaser(model: suggestion)
    $(@el).append(view.render().el)