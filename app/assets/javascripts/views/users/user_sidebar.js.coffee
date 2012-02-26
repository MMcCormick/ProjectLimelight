class LL.Views.UserSidebar extends Backbone.View
  el: $('.sidebar.left')
  template: JST['users/sidebar']
  id: 'user-sidebar'

  initialize: ->
    @model.on('change', @render)

  render: =>
    $(@el).html(@template())

    # Main top nav
    nav = new LL.Views.UserSidebarNav(model: @model)
    $(@el).append(nav.render().el)

    # Follow stats
    follow = new LL.Views.UserSidebarFollowStats(model: @model)
    $(@el).append(follow.render().el)

    # Topic suggestions
    topic_suggestions = new LL.Views.UserSidebarTopicSuggestions(model: @model)
    $(@el).append(topic_suggestions.el)
    LL.App.TopicSuggestions.fetch({data: {id: @model.id}})

    @