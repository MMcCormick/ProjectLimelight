class LL.Views.UserSidebarNav extends Backbone.View
  template: JST['users/sidebar_nav']
  className: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    @