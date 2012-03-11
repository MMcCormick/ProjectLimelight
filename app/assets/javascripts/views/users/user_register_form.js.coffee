class LL.Views.UserRegisterForm extends Backbone.View
  template: JST['users/register_form']
  id: 'user-register-form'

  events:
    "submit form": "registerUser"

  initialize: ->

  render: =>
    $(@el).html(@template())
    @

  registerUser: (e) ->
    e.preventDefault()

    attributes = {}
    for input in $(@el).find('input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    @collection.create attributes,
      wait: true
      beforeSend: ->
        $(self.el).find('.btn-success').attr('disabled', 'disabled')
      success: (data) ->
        self.destroyForm()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeAttr('disabled')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).removeClass('disabled')