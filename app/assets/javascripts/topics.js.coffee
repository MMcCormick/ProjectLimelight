jQuery ->
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

  # Creates a qtip with a form to add types to a topic when an .addTypeB is clicked
  $('.addTypeB').livequery ->
    self = $(@)
    self.qtip({
      content: {
        text: 'Loading...',
        ajax: {
          once: true,
          url: self.data("d").newTypeUrl,
          type: 'get',
          success: (data) ->
            self.qtip('option', {
              'content.text': data,
              'content.ajax': false
            })
          error: (data) ->
            self.qtip('option', {
              'content.text': if data.status == 401 then 'You must sign in to see this user\'s info!' else 'Error'
              'content.ajax': false
            })
          "html"
        }
      }
      style: {classes: 'ui-tooltip-shadow', tip: true},
      position: {
        my: 'top right',
        at: 'bottom middle',
        viewport: $(window)
      },
      show: {event: 'click'},
      hide: {event: 'unfocus'}
    })