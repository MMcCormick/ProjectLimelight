jQuery ->

  # choose to fetch from url on contribute form
  $('.contributeC .picture_options .first').live 'click', (e) ->
    $(@).parent().fadeOut 150, ->
      $(@).siblings('.url.picture').fadeIn 150

  # cancel fetch from url on contribute form
  $('.contributeC .url.picture .cancel').live 'click', (e) ->
    $(@).parent().fadeOut 150, ->
      $(@).siblings('.picture_options').fadeIn 150

  # used to expand pictures in feeds
  $('.img .full-black-icon').live 'click', (e) ->
    self = $(@)
    title = if $(this).parents('.teaser:first').length > 0 then $(this).parents('.teaser:first').find('.titleC a').text() else ''
    $.colorbox({title: title, html: ->
      data = self.parents('.img:first').find('img').data('o')
      return "<img src='"+data.url+"' width='"+data.w+"' height='"+data.h+"' />"
    });
    $.colorbox.resize()