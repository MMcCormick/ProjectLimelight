class LL.Views.UserInviteOptions extends Backbone.View
  template: JST['users/invite_options']
  className: 'invite-options'

  events:
    'click .submit': 'inviteContacts'

  initialize: ->
    @modal = false

  render: =>

    $(@el).html(@template(user: @model))
    if @modal
      $(@el).addClass('modal fade').modal()

    @

  inviteContacts: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    button = $(e.currentTarget)
    payload = {
      message: $(@el).find('.message').val()
      emails: []
    }

    emails = $(@el).find('.emails').val()
    return if $.trim(emails).length == 0

    emails = emails.split(',')
    max = 0
    for email in emails
      break if max > 500
      payload.emails.push $.trim(email)
      max += 1

    return if payload.emails.length == 0

    self = @

    $.ajax
      url: '/api/users/invite_by_email'
      type: 'post'
      dataType: 'json'
      data: payload
      beforeSend: ->
        button.addClass('disabled').text('Sending...')
      complete: ->
        button.removeClass('disabled').text('Send Invites')
      success: (data) ->
        $(self.el).find('.emails,.message').val('').effect('highlight', {color: 'green'}, 500)
        createGrowl(false, "Successfully invited #{payload.emails.length} friends!", '', 'green')
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR)