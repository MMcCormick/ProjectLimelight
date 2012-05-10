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
        $(self.el).find('.btn-success').attr('disabled', 'disabled')
      success: (data) ->
        $(self.el).find('.btn-success').removeAttr('disabled')
        $('.beta-register .form').slideUp 300, ->
          $('.beta-register .confirm').slideDown 300
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeAttr('disabled')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeAttr('disabled')