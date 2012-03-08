class LL.Views.SidebarFooter extends Backbone.View
  template: JST['widgets/sidebar_footer']
  className: 'sidebar-footer'
  tagName: 'section'

  initialize: ->

  render: =>
    $(@el).html(@template())
    @