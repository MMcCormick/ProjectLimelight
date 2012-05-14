class LL.Views.UserBetaSignupForm extends Backbone.View

  events:
    "submit": "betaSignUp"

  initialize: ->

  betaSignUp: (e) =>
    e.preventDefault()

    self = @

    $.ajax(
      url: '/api/beta_signups'
      dataType: 'json'
      type: 'POST'
      data: { email: $('#beta-signup-email').val() }
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Send Me One')
        $(self.el).slideUp 300, ->
          $('.beta-signup-success').slideDown 300
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Send Me One')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Send Me One')
    )