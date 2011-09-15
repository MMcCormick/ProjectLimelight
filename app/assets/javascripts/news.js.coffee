jQuery ->

  # News submission form, handle fetching data from supplied URL
  $('#news_url').live 'blur', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        console.log(data)

        $('#news_url').val(data.embedly.url)
        $('#news_content').focus().val(data.embedly.description)
        $('#news_title').focus().val(data.embedly.title)
        $('#publisher').focus().val(data.embedly.provider_name)

        target = $('#new_news .image-preview .images');
        if data.embedly.images.length > 0
          target.html('').siblings('.default').hide();

          for image in data.embedly.images
            target.append("<img src='"+image.url+"' />")

          target.find('img:not(:first)').hide()
        else
          target.siblings('.default').show()

      'json'
    )

  # Toggle between uploading an image and choosing an image from those found at the given URL
  $('form.core_object .field.image .choices .fetch').live 'click', (e) ->
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      $(@).parents('form.core_object').find('.image-preview .fetch').hide()
      $(@).parents('form.core_object').find('.image-preview .default').show()
      $(@).parents('form.core_object').find('.remote_image_url').val('')
    else
      $(@).addClass('on').siblings().removeClass('on')
      $(@).parents('form.core_object').find('.image-preview .fetch').show()
      $(@).parents('form.core_object').find('.image-preview .upload').hide()
      $(@).parents('form.core_object').find('.image-preview .default').hide()
      $(@).parents('form.core_object').find('input[type="file"]').val('')
      $(@).parents('form.core_object').find('.remote_image_url').val($(@).parents('form.core_object').find('.image-preview .images img:visible').attr('src'))

  # When a user clicks on the upload image element, click the hidden file input to show the choose image dialogue
  $('form.core_object .field.image .choices .upload').live 'click', (e) ->
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      $(@).parents('form.core_object').find('input[type="file"]').val('')
      $(@).parents('form.core_object').find('.image-preview .default').show()
    else
      $(@).parents('form.core_object').find('input[type="file"]').click()

  # When the hidden file input value changes, update shit
  $('form.core_object input[type="file"]').live 'change', (e) ->
    $(@).parents('form.core_object').find('.field.image .choices .upload').addClass('on').siblings().removeClass('on')
    $(@).parents('form.core_object').find('.image-preview .fetch').hide()
    $(@).parents('form.core_object').find('.image-preview .upload').show().html($(@).val())
    $(@).parents('form.core_object').find('.image-preview .default').hide()
    $(@).parents('form.core_object').find('.remote_image_url').val('')

  $('form.core_object .image-preview .fetch .left').live 'click', (e) ->
    target = $(@).siblings('.images').find('img:visible').hide()
    if target.prev().is('img')
      found = target.prev()
    else
      found = $(@).siblings('.images').find('img:last')

    $(@).parents('form.core_object').find('.remote_image_url').val(found.attr('src'))
    found.show()

  $('form.core_object .image-preview .fetch .right').live 'click', (e) ->
    target = $(@).siblings('.images').find('img:visible').hide()
    if target.next().is('img')
      found = target.next()
    else
      found = $(@).siblings('.images').find('img:first')

    $(@).parents('form.core_object').find('.remote_image_url').val(found.attr('src'))
    found.show()