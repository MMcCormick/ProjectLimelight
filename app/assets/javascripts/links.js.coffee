jQuery ->

  # TODO: Refactor this into it's own object, clean it up.
  fetchImages = (pullFrom) ->
    targetForm = pullFrom.parents('form.core_object:first')
    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: pullFrom.val()
      (data) ->
        target = targetForm.find('.image-preview .images');
        if data.embedly.images.length > 0
          target.html('').siblings('.default').hide();

          for image in data.embedly.images
            target.append("<img src='"+image.url+"' />")

          target.find('img:not(:first)').hide()

        else
          target.siblings('.default').show()
          targetForm.find('.remote_image_url').val('')

        if (targetForm.find('.fetch.on').length > 0)
          targetForm.find('.remote_image_url').val(target.find('img:first').attr('src'))

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
      parent.find('.image_upload_cache').val('')
      parent.find('.remote_image_url').val(parent.find('.image-preview .images img:visible').attr('src'))

  # When a user clicks on the upload image element, click the hidden file input to show the choose image dialogue
  $('#link_uploadB').live 'click', (e) ->
    parent = $('#new_picture')
    if ($(@).hasClass('on'))
      $(@).removeClass('on')
      $('#link_asset_image_image_cache').val('')
      parent.find('.image-preview .default').show()
      parent.find('.image-preview .upload').hide()
    else
      $(@).addClass 'on'
      $('#link_pupB').click()

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

  # Link submission form, handle fetching data from supplied URL
  $('#link_source_url').live 'blur', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        $('#link_url, #new_link .image_fetch_url').val(data.embedly.url)
        fetchImages($('#new_link .image_fetch_url'))
#        $('#link_content').focus().val(data.embedly.description)
        $('#link_title').focus().val(data.embedly.title)
        $('#link_source_name').focus().val(data.embedly.provider_name)

      'json'
    )