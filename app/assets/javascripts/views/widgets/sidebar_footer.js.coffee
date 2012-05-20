class LL.Views.SidebarFooter extends Backbone.View
  template: JST['widgets/sidebar_footer']
  className: 'section sidebar-footer'
  tagName: 'div'

  initialize: ->

  render: =>
    $(@el).html(@template())
    @