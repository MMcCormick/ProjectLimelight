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

      'json'
    )