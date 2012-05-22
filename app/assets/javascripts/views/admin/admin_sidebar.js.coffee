class LL.Views.AdminSidebar extends Backbone.View
  template: JST['admin/sidebar']
  el: $('.sidebar')

  initialize: ->

  render: =>
    $(@el).html(@template(page: @page)).attr('id', 'admin-sidebar')
    @