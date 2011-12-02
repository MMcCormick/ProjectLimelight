isUrl = (s) ->
  regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
  regexp.test(s);

jQuery ->

  ####
  # CONTRIBUTE FORM
  ####

  setContributeToVideo = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_video').attr('action'))
    talkForm.find('#talk_content').attr('name', 'video[content]').parents('.lClear:first').removeClass('required').find('label').text('Say something about this video...')
    talkForm.find('#talk_content_raw').attr('name', 'video[content_raw]')
    talkForm.find('#talk_ooc_mentions').attr('name', 'video[ooc_mentions]')

  # Video submission form, handle fetching data from supplied URL
  $('.contributeC #video_fetch').live 'change', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        provider = data.embedly.provider_name
        switch provider
          when 'YouTube'
            video_id = data.embedly.payload.video.data.id
            html = "<iframe
                      width='120'
                      height='120'
                      src='http://www.youtube.com/embed/"+video_id+"'
                      frameborder='0' allowfullscreen>
                    </iframe>"
          when 'Vimeo'
            video_id = data.embedly.payload.video_id
            html = "<iframe
                      width='120'
                      height='120'
                      src='http://player.vimeo.com/video/"+video_id+"' frameborder='0'
                      webkitAllowFullScreen allowFullScreen>
                    </iframe>"
          when 'Dailymotion'
            video_id_parts = $(data.embedly.payload.html).attr('src').split('/')
            video_id = video_id_parts[video_id_parts.length-1]
            html = "<iframe
                      frameborder='0'
                      width='120'
                      height='120'
                      src='http://www.dailymotion.com/embed/video/"+video_id+"'>
                    </iframe>"
          else
            html = null
            video_id = data.embedly.payload.video_id


        parentForm = self.parents('.contributeC:first')
        videoForm = parentForm.find('.new_video')
        clone = videoForm.find('.shared').clone()
        parentForm.find('.main_content').prepend(clone)
        target = clone.find('.preview')

        if html
          target.html(html)
        else
          target.html('<div class="none">Sorry, no video embed available.')

        clone.find('#video_source_url').val(data.embedly.url)
        clone.find('#video_title').focus().val(data.embedly.title)
        clone.find('#video_source_name').val(provider)
        clone.find('#video_source_video_id').val(video_id)

        clone.fadeIn 150

        $('#video_fetch').val('').blur().parent().fadeOut(150)
        setContributeToVideo(parentForm)

      'json'
    )

  ####
  # END
  ####