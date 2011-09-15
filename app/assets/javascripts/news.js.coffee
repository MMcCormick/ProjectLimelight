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
      $(@).parents('form.core_object').find('.field.image .image-preview .fetch').hide(250)
    else
      $(@).addClass('on').siblings().removeClass('on')
      $(@).parents('form.core_object').find('.field.image .image-preview .fetch').show(250)
      $(@).parents('form.core_object').find('.field.image .image-preview .upload').hide(250)

  # When a user clicks on the upload image element, click the hidden file input to show the choose image dialogue
  $('form.core_object .field.image .choices .upload').live 'click', (e) ->
    $(@).parent().find('input[type="file"]').click()

  # When the hidden file input value changes, update shit
  $('form.core_object input[type="file"]').live 'change', (e) ->
    $(@).parents('form.core_object').find('.field.image .choices .upload').addClass('on').siblings().removeClass('on')
    $(@).parents('form.core_object').find('.field.image .image-preview .fetch').hide()
    $(@).parents('form.core_object').find('.field.image .image-preview .upload').show()

  $('form.core_object .image-preview .fetch .left').live 'click', (e) ->
    target = $(@).siblings('.images').find('img:visible').hide()
    if target.prev().is('img')
      target.prev().show()
    else
      $(@).siblings('.images').find('img:last').show()

  $('form.core_object .image-preview .fetch .right').live 'click', (e) ->
    target = $(@).siblings('.images').find('img:visible').hide()
    console.log target.next()
    if target.next().is('img')
      target.next().show()
    else
      $(@).siblings('.images').find('img:first').show()