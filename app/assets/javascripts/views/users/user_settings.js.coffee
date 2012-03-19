class LL.Views.UserSettings extends Backbone.View
  el: $('#user-settings')

  events:
    'click .s-btn': 'updateSetting'
    'click .radio-btn': 'updateRadioSetting'

  initialize: ->

  updateSetting: (e) =>
    button = $(e.target)

    data = {}
    data[button.attr('name')] = if button.hasClass('btn-info') then 'false' else 'true'

    $.ajax
      url: '/api/users'
      type: 'put'
      dataType: 'json'
      data: data
      beforeSend: ->
        button.button('loading')
      complete: ->
        button.button('reset')
        button.toggleClass('btn-info')
        button.text(if button.hasClass('btn-info') then 'On' else 'Off')

  updateRadioSetting: (e) =>
    button = $(e.target)

    data = {}
    data[button.attr('name')] = button.data('value')

    unless button.hasClass('btn-info')
      $.ajax
        url: '/api/users'
        type: 'put'
        dataType: 'json'
        data: data
        beforeSend: ->
          button.oneTime 500, 'loading', ->
            button.button('loading')
        complete: ->
          button.stopTime 'loading'
          button.button('reset')
          button.toggleClass('btn-info')
          button.siblings().removeClass('btn-info')
