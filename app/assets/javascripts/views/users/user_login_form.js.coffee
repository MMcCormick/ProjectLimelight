class LL.Views.UserLoginForm extends Backbone.View
  template: JST['users/login_form']
  id: 'user-login-form'

  initialize: ->

  render: =>
    $(@el).html(@template())
    @