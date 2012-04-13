class LL.Views.TopicSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'topic-sidebar'

  initialize: ->

  render: =>

    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').fit.large}' />")

    # Talk form
    talk = new LL.Views.TopicSidebarTalk(model: @model)
    $(@el).append(talk.render().el)

    # Main top nav
    nav = new LL.Views.TopicSidebarNav(model: @model)
    $(@el).append(nav.render().el)

    @