class LL.Views.RequestInvite extends Backbone.View
  template: JST['widgets/request_invite']
  className: 'request-invite'
  tagName: 'div'

  events:
    'click .btn': 'showLogin'

  initialize: ->

  render: =>
    $(@el).html(@template())
    @

  showLogin: (e) =>
    LL.LoginBox.showModal()