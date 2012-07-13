class LL.Views.SocialSettings extends Backbone.View
  template: JST['users/social_settings']
  className: 'social-settings'

  events:
    'click .radio-btn': 'updateRadioSetting'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    $(@el).find('.qm.auto_follow').qtip
      overwrite: false
      position:
        my: 'middle left'
        at: 'middle right'
        viewport: $(window)
      style:
        tip: true
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-light'
      show:
        solo: true
      content:
        text: (api) ->
          "
           Re-creating your social network is a pain. When users you are friends with on another social network join
           Limelight we will automatically follow them on Limelight for you (and they will automatically follow you on Limelight).
           <br /><br />
           This will NOT post anything to your other networks.
          "

    $(@el).find('.qm.og_follows').qtip
      overwrite: false
      position:
        my: 'middle left'
        at: 'middle right'
        viewport: $(window)
      style:
        tip: true
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-light'
      show:
        solo: true
      content:
        text: (api) ->
          "
           When you follow a user or topic on Limelight we will add to the limelight area of your Facebook Timeline. Example:
           <br /><br />
           <img width='500' src='/assets/images/fb_follow_example.png' />
          "

    @

  updateRadioSetting: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

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
        success: (data) ->
          globalSuccess(data)
        error: (jqXHR, textStatus, errorThrown) ->
          $(self.el).removeClass('disabled')
          globalError(jqXHR)