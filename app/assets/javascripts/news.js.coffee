jQuery ->

  # TODO: Refactor this into it's own object, clean it up.
  fetchImages = (pullFrom) ->
    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: pullFrom.val()
      (data) ->
        target = $('form.core_object .image-preview .images');
        if data.embedly.images.length > 0
          target.html('').siblings('.default').hide();

          for image in data.embedly.images
            target.append("<img src='"+image.url+"' />")

          $('form.core_object .remote_image_url').val(target.find('img:first').attr('src'))
          target.find('img:not(:first)').hide()

        else
          target.siblings('.default').show()
          $('form.core_object .remote_image_url').val('')

      'json'
    )

  # Update the images when the image fetch URL is changed
  $('form.core_object .image_fetch_url').live 'change', (e) ->
    fetchImages($(@))

  # Toggle between uploading an image and choosing an image from those found at the given URL
  $('form.core_object .field.image .choices .fetch').live 'click', (e) ->
    parent = $(@).parents('form.core_object')
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      parent.find('.image-preview .fetch').hide()
      parent.find('.image-preview .default').show()
      parent.find('.remote_image_url').val('')
    else
      $(@).addClass('on').siblings().removeClass('on')
      parent.find('.image-preview .fetch').show()
      parent.find('.image-preview .upload').hide()
      parent.find('.image-preview .default').hide()
      parent.find('input[type="file"]').val('')
      parent.find('.remote_image_url').val(parent.find('.image-preview .images img:visible').attr('src'))

  # When a user clicks on the upload image element, click the hidden file input to show the choose image dialogue
  $('#news_uploadB').live 'click', (e) ->
    parent = $('#new_picture')
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      $('#news_asset_image_image_cache').val('')
      parent.find('.image-preview .default').show()
      parent.find('.image-preview .upload').hide()
    else
      $(@).addClass 'on'
      $('#news_pupB').click()

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

        $('#news_url, #new_news .image_fetch_url').val(data.embedly.url)
        fetchImages($('#new_news .image_fetch_url'))
        $('#news_content').focus().val(data.embedly.description)
        $('#news_title').focus().val(data.embedly.title)
        $('#publisher').focus().val(data.embedly.provider_name)

      'json'
    )