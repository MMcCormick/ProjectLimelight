isUrl = (s) ->
  regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
  regexp.test(s);

jQuery ->

  # Video submission form, handle fetching data from supplied URL
  $('#video_source_url').live 'blur', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        switch data.embedly.provider_name
          when 'YouTube'
            video_id = data.embedly.payload.video.data.id
            $('#new_video .preview').find('.content').html("<iframe
                                                                    width='220'
                                                                    height='155'
                                                                    src='http://www.youtube.com/embed/"+video_id+"'
                                                                    frameborder='0' allowfullscreen>
                                                                    </iframe>")
            $('#new_video .preview').show(200)
          when 'Vimeo'
            video_id = data.embedly.payload.video_id
            $('#new_video .preview').find('.content').html("<iframe
                                                                    width='220'
                                                                    height='155'
                                                                    src='http://player.vimeo.com/video/"+video_id+"' frameborder='0'
                                                                    webkitAllowFullScreen allowFullScreen>
                                                                    </iframe>")
            $('#new_video .preview').show(200)
          when 'Dailymotion'
            video_id_parts = $(data.embedly.payload.html).attr('src').split('/')
            video_id = video_id_parts[video_id_parts.length-1]
            $('#new_video .preview').find('.content').html("<iframe
                                                                    frameborder='0'
                                                                    width='220'
                                                                    height='155'
                                                                    src='http://www.dailymotion.com/embed/video/"+video_id+"'>
                                                                    </iframe>")
            $('#new_video .preview').show(200)
          else
            # TODO: Handle this...
            foo = 'bar'

        $('#video_source_url').val(data.embedly.url)
#        $('#video_content').focus().val(data.embedly.description)
        $('#video_title').focus().val(data.embedly.title)
        $('#video_source_name').val(data.embedly.provider_name)
        $('#video_source_video_id').val(video_id)

      'json'
    )