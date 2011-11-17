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