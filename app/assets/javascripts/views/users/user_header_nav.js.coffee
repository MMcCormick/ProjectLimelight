class LL.Views.UserHeaderNav extends Backbone.View
  template: JST['users/header_nav']
  id: 'header-user-nav'
  className: 'dropdown'

  initialize: ->

  render: =>
    $(@el).html(@template(user: @model))
    @