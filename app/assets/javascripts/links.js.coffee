jQuery ->

  # Update the images when the image fetch URL is changed
  $('form.core_object .image_fetch_url').live 'change', (e) ->
    fetchImages($(@))

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