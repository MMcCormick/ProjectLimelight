window.LL =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    @App =  new LL.Views.App()
    @Header = new LL.Views.Header(model: LL.App.current_user)

    unless LL.App.current_user
      @LoginBox = new LL.Views.SplashPage()

    # hack because facebook login appends stupid things to the url
    if LL.App.current_user && (window.location.hash == '#_=_' || window.location.pathname == '/_=_')
      window.location = '/'

    @Router = new LL.Router()
    Backbone.history.start(pushState: true)

    if LL.App.current_user && LL.App.current_user.get('username_reset') == true
      reset = new LL.Views.UsernameReset(model: LL.App.current_user)
      $(reset.render().el).modal
        backdrop: 'static'
        keyboard: false
        show: true

jQuery ->

  $('.freebase-autocomplete').livequery ->
    $(@).each (i,val) ->
      $(val).suggest(
        key: 'AIzaSyCWYALjkKapMjYcrKlvLRYuihb6VxAlGQQ'
        scoring: 'entity'
        flyout: true
        zIndex: 10000
      ).bind 'fb-select', (e,data) ->
        $(e.currentTarget).next().val(data.mid)


  # Start up Backbone
  LL.init()

  # Bootstrap tooltips
  $('[rel="tooltip"]').livequery ->
    $(@).tooltip()

  window.globalSuccess = (data) ->
    if data.flash
      createGrowl false, data.flash, 'Success', 'green'

    if data.redirect
      window.location = data.redirect

  window.globalError = (jqXHR, target=null) ->
    data = $.parseJSON(jqXHR.responseText)

    if data.flash
      createGrowl false, data.flash, 'Error', 'red'

    switch jqXHR.status
      when 422
        if target && data && data.errors
          target.find('.alert-error').remove()
          errors_container = $('<div/>').addClass('alert alert-error').prepend('<a class="close" data-dismiss="alert">x</a>')
          for key,errors of data.errors
            if errors instanceof Array
              for error in errors
                errors_container.append("<div>#{error}</div>")
            else
              errors_container.append("<div>#{errors}</div>")
          target.find('.errors').show().prepend(errors_container)

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

  # case insensitive contains selector
  jQuery.expr[':'].Contains = (a, i, m) ->
    return jQuery(a).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0