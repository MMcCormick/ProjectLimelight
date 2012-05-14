class LL.Views.UserUseInviteForm extends Backbone.View

  events:
    "submit": "useInvite"

  initialize: ->

  useInvite: (e) =>
    e.preventDefault()

    invite_code = $('#invite_code_code').val()

    self = @

    $.ajax(
      url: '/api/invite_codes/check'
      dataType: 'json'
      type: 'POST'
      data: {code: invite_code}
      beforeSend: ->
        $(self.el).find('.btn-success').attr('disabled', 'disabled')
      success: (data) ->
        self.splash.showRegister()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeAttr('disabled')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeAttr('disabled')
    )