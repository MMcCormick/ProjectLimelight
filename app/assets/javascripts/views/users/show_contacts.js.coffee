class LL.Views.ShowContacts extends Backbone.View
  template: JST['users/show_contacts']
  className: 'contacts'

  events:
    'click .submit': 'inviteContacts'
    'click .contact': 'contactOn'
    'click .check-all': 'checkAll'
    'keyup .filter': 'filterContacts'

  initialize: ->

  render: =>
    $(@el).html(@template(contacts: contacts))

    @

  contactOn: (e) =>
    contact = $(e.currentTarget)
    contact.toggleClass('on')
    if contact.hasClass('on')
      contact.find('input').prop("checked", "check")
    else
      contact.find('input').prop("checked", "")
      $('.check-all').removeClass('on')
      $('.check-all').find('input').prop("checked", "")

  checkAll: (e) =>
    button = $(e.currentTarget)
    button.toggleClass('on')
    if button.hasClass('on')
      button.find('input').prop("checked", "check")
      $('.contact:not(.on)').click()
    else
      button.find('input').prop("checked", "")
      $('.contact.on').click()

  inviteContacts: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    button = $(e.currentTarget)
    payload = {
      message: $(@el).find('.message').val()
      emails: []
    }

    $('li.on').each (i, val) ->
      payload.emails.push contacts[parseInt($(val).data("index"))]["email"]

    return if payload.emails.length == 0

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
        $('.submit,.contact-list,.check-all,.filter,h5,.message').remove()
        $('.update').html(data.flash)
        setTimeout ->
          window.location = '/'
        , 3000
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR)

  filterContacts: (e) =>
    filter = $(e.currentTarget).val()
    if (filter)
      console.log filter
      $(@el).find(".data:not(:Contains(" + filter + "))").parent().hide()
      $(@el).find(".data:Contains(" + filter + ")").parent().show()
    else
      $(@el).find("li").show()