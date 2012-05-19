class LL.Views.UserSidebarInvite extends Backbone.View
  template: JST['users/sidebar_invite']
  tagName: 'div'
  className: 'section sidebar-invite'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @