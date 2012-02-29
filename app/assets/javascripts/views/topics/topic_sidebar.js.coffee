class LL.Views.TopicSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'topic-sidebar'

  initialize: ->
    @model.on('change', @render)

  render: =>
    # Main top nav
    nav = new LL.Views.TopicSidebarNav(model: @model)
    $(@el).append(nav.render().el)

    @