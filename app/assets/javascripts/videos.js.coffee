jQuery ->

  $('.teaser.video .play-video').live 'click', (e) ->
    $(@).replaceWith($(@).data('embed'))