class LL.Views.UserSidebarInvite extends Backbone.View
  template: JST['users/sidebar_invite']
  tagName: 'div'
  className: 'section sidebar-invite'

  events:
    'click div': 'showInvite'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @

  showInvite: (e) =>
    view = new LL.Views.UserInviteOptions(model: @model)
    view.modal = true
    view.render()