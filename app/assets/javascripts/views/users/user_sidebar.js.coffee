class LL.Views.UserSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'user-sidebar'

  initialize: ->

  render: =>
    # User talk form
    talk = new LL.Views.UserSidebarTalk(model: @model)
    $(@el).append(talk.render().el)

    # Main top nav
    nav = new LL.Views.UserSidebarNav(model: @model)
    nav.page = @page
    $(@el).append(nav.render().el)

    # Follow stats
    follow = new LL.Views.UserSidebarFollowStats(model: @model)
    follow.page = @page
    $(@el).append(follow.render().el)

    # Topic suggestions
#    if LL.App.current_user == @model
#      topic_suggestions = new LL.Views.UserSidebarTopicSuggestions(model: @model)
#      $(@el).append(topic_suggestions.el)
#      LL.App.TopicSuggestions.fetch({data: {id: @model.id}})

    # Follow stats
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @