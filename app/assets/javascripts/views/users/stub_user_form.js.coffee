class LL.Views.StubUserForm extends Backbone.View
  template: JST['users/stub_user_form']
  tagName: 'form'

  events:
    "click .submit": "createStubUser"

  initialize: ->

  render: =>
    $(@el).html(@template())

    $('#feed').append(@el)

    @

  createStubUser: (e) =>
    e.preventDefault()

    attributes = {}
    for input in $(@el).find('input')
      attributes[$(input).attr('name')] = $(input).val()

    self = @

    $.ajax(
      url: '/api/users/stubs'
      dataType: 'json'
      type: 'POST'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').attr('disabled', 'disabled')
      success: (data) ->
        globalSuccess(data)
        $(self.el).find('.btn-success').removeAttr('disabled')
      error: (jqXHR, textStatus, errorThrown) ->
        globalError(jqXHR, $(self.el))
        $(self.el).find('.btn-success').removeAttr('disabled')
      complete: ->
        $(self.el).find('.btn-success').removeAttr('disabled')
    )