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
      target.find('#talk_content').focus()


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

  $('.mention').mentionable()

  $('.mention-ooc .auto input').autocomplete($('#static-data').data('d').autocomplete, {
    minChars: 2,
    width: 450,
    matchContains: true,
    matchSubset: false,
    autoFill: false,
    selectFirst: true,
    mustMatch: false,
    searchKey: 'term',
    max: 10,
    bucket: false,
    bucketType: ["topic"],
    extraParams: {"types[]":["topic"]},
    dataType: 'json',
    delay: 150,
    allowNewTopic: true,
    formatItem: (row, i, max) ->
      return row.formattedItem
    formatMatch: (row, i, max) ->
      return row.term
    formatResult: (row) ->
      return row.term
  }).result (event, data, formatted) ->
    if (data.bucketType == 'user')
      window.location = '/users/'+data.term
    else if (data.bucketType == 'topic')
      window.location = data.data.url

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
