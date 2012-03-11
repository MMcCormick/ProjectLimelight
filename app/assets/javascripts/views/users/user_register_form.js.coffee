class LL.Views.UserRegisterForm extends Backbone.View
  template: JST['users/register_form']
  id: 'user-register-form'

  initialize: ->

  render: =>
    $(@el).html(@template())
    @