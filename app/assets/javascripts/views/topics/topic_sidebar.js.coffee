class LL.Views.TopicSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'topic-sidebar'

  initialize: ->

  render: =>

    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').fit.large}' />")

    # Talk form
#    talk = new LL.Views.TopicSidebarTalk(model: @model)
#    $(@el).append(talk.render().el)

    # Topic sidebar
    if @model.get('summary') || @model.get('aliases').length > 0 || (LL.App.current_user && LL.App.current_user.hasRole('admin'))
      nav = new LL.Views.TopicSidebarNav(model: @model)
      $(@el).append(nav.render().el)

    # Static Links
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @