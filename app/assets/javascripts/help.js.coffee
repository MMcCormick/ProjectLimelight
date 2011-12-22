jQuery ->

  $('#hp .more').live 'click', (e) ->
    $('.hf').fadeOut(200)
    $('#hp > div:not(.close)').hide()
    $('#hp .master').show()
    if ($('#top-contribute:visible').length == 1)
      $('#contribute').click()

  $('.hf').live 'mouseover', (e) ->
    $(@).addClass('on')

  $('.hf').live 'mouseout', (e) ->
    $(@).removeClass('on')

  $('#hp .tutorials > div').live 'mouseover', (e) ->
    $('.hf').removeClass('on')
    $($(@).data('t')).addClass('on', 150)

  $('#hp .tutorials > div').live 'mouseout', (e) ->
    $('.hf').removeClass('on')

  $('#hp-up').live 'click', (e) ->
    $('#hp .master').hide()
    $('#hp .up').show()
    $('#hp .up').find('.tutorials > div').each (i,val) ->
      $($(val).data('t')).show('scale', {}, 150)

  $('#hp-contrib').live 'click', (e) ->
    $('#hp .master').hide()
    $('#hp .contrib').show()

    if ($('#top-contribute:visible').length == 0)
      $('#contribute').click()

    $('#hp .contrib').find('.tutorials > div').each (i,val) ->
      $($(val).data('t')).show('scale', {}, 150)

  $('#tutorial-show-feed').livequery ->
    if ($('#hp-feed').length > 0)
      $('#hp-feed').oneTime 1000, 'start_tutorial', ->
        $(@).click()

  $('#hp-feed').live 'click', (e) ->
    # go to homepage if not there
    if (window.location.pathname != '/')
      window.location = '/?tutorial=feed'
      return false

    $('#hp .master').hide()
    $('#hp .feed').show()

    $('#hp .feed').find('.tutorials > div').each (i,val) ->
      $($(val).data('t')).show('scale', {}, 150)

  $('#topic-panel[data-id="4ec69d9fcddc7f9fe80000b8"]').livequery ->
    if ($('#hp-topic').length > 0)
      $('#hp-topic').oneTime 1000, 'start_tutorial', ->
        $(@).click()

  $('#hp-topic').live 'click', (e) ->
    # go to limelight topic if not on that page
    if ($('[data-push="4ec69d9fcddc7f9fe80000b8"]').length == 0)
      window.location = '/limelight'
      return false

    $('#hp .master').hide()
    $('#hp .topic').show()

    $('#hp .topic').find('.tutorials > div').each (i,val) ->
      $($(val).data('t')).show('scale', {}, 150)