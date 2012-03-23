class LL.Views.UsernameReset extends Backbone.View
  template: JST['users/username_reset']
  className: 'username-reset modal'

  events:
    'click .btn': 'setUsername'
    'keypress input': 'submitForm'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @

  submitForm: (e) =>
    if e.keyCode == 13 # enter
      @setUsername()

  setUsername: =>
    return if $(@el).hasClass('disabled')

    self = @

    $.ajax '/api/users',
      type: 'put'
      data: {username: $('#username_reset_value').val()}
      dataType: 'json'
      beforeSend: ->
        $(self.el).addClass('disabled')
      success: (data) ->
        window.location = '/'
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR, $(self.el))