isUrl = (s) ->
  regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
  regexp.test(s);

jQuery ->

  # Video submission form, handle fetching data from supplied URL
  $('#video_url').live 'blur', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        console.log(data)

        switch data.embedly.provider_name
          when 'YouTube'
            video_id = data.embedly.payload.video.data.id
            $('#new_video .preview').show(200).find('.media').html("<iframe
                                                                    width='220'
                                                                    height='155'
                                                                    src='http://www.youtube.com/embed/"+video_id+"'
                                                                    frameborder='0' allowfullscreen>
                                                                    </iframe>")
          when 'Vimeo'
            video_id = data.embedly.payload.video_id
            $('#new_video .preview').show(200).find('.media').html("<iframe
                                                                    width='220'
                                                                    height='155'
                                                                    src='http://player.vimeo.com/video/"+video_id+"' frameborder='0'
                                                                    webkitAllowFullScreen allowFullScreen>
                                                                    </iframe>")
          else
            # TODO: Handle this...
            console.log 'Embed link could not be created...'

        $('#video_url').val(data.embedly.url)
        $('#video_content').focus().val(data.embedly.description)
        $('#video_title').focus().val(data.embedly.title)
        $('#video_provider_name').val(data.embedly.provider_name)
        $('#video_provider_video_id').val(video_id)

      'json'
    )