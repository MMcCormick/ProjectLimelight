class LL.Views.UserRegisterForm extends Backbone.View
  el: $('.beta-register form')

  events:
    "submit": "registerUser"

  initialize: ->

  registerUser: (e) =>
    e.preventDefault()

    attributes = {}
    for input in $(@el).find('input[type="text"],input[type="hidden"],input[type="email"],input[type="password"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    @collection.create attributes,
      wait: true
      beforeSend: ->
        $(self.el).find('.btn-success').button('loading')
      success: (data) ->
        $(self.el).find('.btn-success').button('reset')
        $('.register-form').replaceWith("<h4>Thanks for registering! Only one step left. Please check your email for the confirmation link.</h4>")
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').button('reset')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').button('reset')