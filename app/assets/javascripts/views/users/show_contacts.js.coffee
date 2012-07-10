class LL.Views.ShowContacts extends Backbone.View
  template: JST['users/show_contacts']
  className: 'contacts'

  events:
    'click .submit': 'inviteContacts'
    'click .contact': 'contactOn'
    'click .check-all': 'checkAll'

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
    button = $(e.currentTarget)
    data = []
    $('li.on').each (i, val) ->
      data.push contacts[parseInt($(val).data("index"))]["email"]
    console.log(data)

    $.ajax
      url: '/api/users/invite_by_email'
      type: 'post'
      dataType: 'json'
      data: {emails: data}
      beforeSend: ->
        button.oneTime 500, 'loading', ->
          button.button('loading')
      complete: ->
        button.stopTime 'loading'
        button.button('reset')
      success: (data) ->
        $('.contact-list').html('')
        $('.submit').remove()
        $('.update').html(data.flash)
        setTimeout ->
          window.location = '/'
        , 3000
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR)