class LL.Views.TopicSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'topic-sidebar'

  initialize: ->

  render: =>
    # User talk form
    talk = new LL.Views.TopicSidebarTalk(model: @model)
    $(@el).append(talk.render().el)

    # Main top nav
    nav = new LL.Views.TopicSidebarNav(model: @model)
    $(@el).append(nav.render().el)

    @