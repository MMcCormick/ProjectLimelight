jQuery ->

  # When a user clicks on the upload image element, click the hidden file input to show the choose image dialogue
  $('#picture_uploadB').live 'click', (e) ->
    parent = $('#new_picture')
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      $('#picture_asset_image_image_cache').val('')
      parent.find('.image-preview .default').show()
      parent.find('.image-preview .upload').hide()
    else
      $(@).addClass 'on'
      $('#picture_pupB').click()

  $('.teaser .full-black-icon').live 'click', (e) ->
    self = $(@)
    title = $(this).parents('.teaser:first').find('.titleC a').text()
    $.colorbox({title: title, html: ->
      return "<img src='"+self.parents('.img:first').find('img').data('original')+"' />"
    });
