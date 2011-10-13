jQuery ->

#  /*
#   * GENERAL OBJECTS
#   */

  $('#contribute, #add_response').live 'click', (e) ->
    target = $($(@).data('target'))
    if target.is(':visible')
      target.slideUp(200)
    else
      target.slideDown(200)


  $('.contributeC .options .option').live 'click', (e) ->
    $(@).parents('.contributeC:first').find('div.form').hide()
    $($(@).data('target')).parents('.form').show()
    $(@).addClass('on').siblings().removeClass('on')

  # Help tooltips on core object submission forms
  $('form.core_object .field').livequery ->
    self = $(@)
    if self.data 'tip'
      self.qtip({
        content:
          self.data 'tip'
        style:
          classes: 'ui-tooltip-red ui-tooltip-shadow'
        position:
          my: 'left center'
          at: 'right center'
      })

  $('.mention').mentionable(
  ).mentionAdded (crap, data)->
    if data.bucketType == 'topic'
      console.log data
      console.log $(@)

  # Automatically click the "load more" button if it is visible for more than .5 secs
  $(window).scroll ->
    if !$('#load-more').hasClass('on') && isScrolledIntoView($('#load-more'), true)
      $('#load-more').addClass('on')
      $('#load-more').oneTime(500, 'load_feed_page', ->
        $(@).click()
      )
    else if !isScrolledIntoView($('#load-more'), true)
      $('#load-more').removeClass('on')
      $('#load-more').stopTime('load_feed_page')

  $('#load-more').live 'click', (e) ->
    $(@).addClass('on')
    $(@).html("loading...")

  # Automatically click if visible on page load
  if $('#load-more').length > 0 && isScrolledIntoView($('#load-more'), true)
    $('#load-more').click()