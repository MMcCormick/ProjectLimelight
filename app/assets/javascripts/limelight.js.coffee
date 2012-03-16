# hack because facebook login appends stupid things to the url
if window.location.hash == '#_=_'
  window.location = '/'

window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    @App =  new LL.Views.App()
    @Header = new LL.Views.Header(model: LL.App.current_user)

    @Router = new LL.Router()
    Backbone.history.start(pushState: true)

jQuery ->

  # Start up Backbone
  LL.init()

  # Bootstrap tooltips
  $('[rel="tooltip"]').livequery ->
    $(@).tooltip()

  # Global error function
  window.globalError = (jqXHR, target=null) ->
    console.log jqXHR
    data = $.parseJSON(jqXHR.responseText)

    if data.flash
      createGrowl false, data.flash, 'Error', 'red'

    switch jqXHR.status
      when 422
        if target && data && data.errors
          target.find('.alert-error').remove()
          errors = $('<div/>').addClass('alert alert-error').prepend('<a class="close" data-dismiss="alert">x</a>')
          for key,error of data.errors
            errors.append("<div>#{error}</div>")
          target.find('.errors').prepend(errors)

  # Use gritter to create 'growl' notifications.
  # @param bool persistent Are the growl notifications persistent or do they fade after time?
  window.createGrowl = (persistent, content, title, theme) ->
    $.gritter.add
      # (string | mandatory) the heading of the notification
      title: title
      # (string | mandatory) the text inside the notification
      text: content
      # (string | optional) the image to display on the left
      image: false
      # (bool | optional) if you want it to fade out on its own or just sit there
      sticky: false
      # (int | optional) the time you want it to be alive for before fading out (milliseconds)
      time: 8000
      # (string | optional) the class name you want to apply directly to the notification for custom styling
      class_name: 'gritter-'+theme
      # (function | optional) function called before it opens
      before_open: ->
      # (function | optional) function called after it opens
      after_open: (e) ->
      # (function | optional) function called before it closes
      before_close: (e, manual_close) ->
        # the manual_close param determined if they closed it by clicking the "x"
      # (function | optional) function called after it closes
      after_close: ->