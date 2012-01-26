jQuery ->

  ####
  # CONTRIBUTE FORM
  ####

  resetContribute = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.attr('action', talkForm.data('old-action'))
    talkForm.find('#talk_content').attr('name', 'talk[content]').parents('.lClear:first').addClass('required').find('label').text('What do you want to talk about?')
    targetForm.find('.response .image, .response .title, .response .created_at').text('')
    targetForm.find('.response').removeClass('with-image')
    $('#talk_parent_id').val('')

  suggestMentions = (target) ->
    if ($.trim(target.val()).length != 0)
      target.stopTime('mention-suggestions')
      target.oneTime 1000, 'mention-suggestions', ->
        $.ajax({
          url: $('#static-data').data('d').mentionSuggestionUrl,
          type: 'get',
          dataType: 'json',
          data: {text: target.siblings('.data').val()}
          success: (data) ->
            suggestionBox = target.parents('form:first').find('.suggestions')
            suggestionBox.find('.placeholder:visible').remove()
            $(data.suggestions).each (i,val) ->
              if (suggestionBox.find('.ms_'+val.topics[0].slug).length == 0)
                suggestionBox.find('.none').hide()
                placeholder = $('<div/>').addClass('placeholder ms_'+val.topics[0].slug).append("<div class='name'>"+val.topics[0].topic.name+"</div><div class='suggestion-group'></div>")
                $(val.topics).each (i,data) ->
                  suggestion = $('<div/>').addClass('suggestion').data('id', data.topic._id).data('text', data.match).text(data.topic.name+" ("+(if data.topic.primary_type then data.topic.primary_type else 'No Type')+")")
                  placeholder.find('.suggestion-group').append(suggestion)
                suggestionBox.append(placeholder)
            if suggestionBox.find('.placeholder:visible').length == 0
              suggestionBox.find('.none').show()
        })

  $('#contribute').live 'click', (e) ->
    if !$logged
      $('#register').click()
      return false

    $('.contributeC').hide()

    form = $('#contribute-top')
    if form.length == 0
      form = $('#blank-contribute').clone()
      form.attr('id', 'contribute-top')
      $('body').append(form)

    form.css({'left':$(@).offset().left - 20})

    form.fadeIn(250)

  # handle option choices on contribute form (clicking add picture/video/link)
  $('.contributeC .options .option').live 'click', (e) ->
    $self = $(@)
    parentForm = $self.parents('.contributeC:first')

    if ($self.hasClass('on'))
      return

    $self.siblings('.option').fadeOut 100, ->
      fade = if $self.hasClass 'picture' then 1 else 150
      $self.addClass 'on', fade, ->
        $self.find('.cancel').fadeIn(100)

        if $self.hasClass 'picture'
          parentForm.find('.picture_options').fadeIn 100
        else if $self.hasClass 'link'
          parentForm.find('.url.link').fadeIn 100

  # handle option cancel on contribute form
  $('.contributeC .options .option .cancel').live 'click', (e) ->
    $self = $(@).parent()
    $('.contributeC .picture_options,.contributeC .url.picture,.contributeC .url.video,.contributeC .url.link').fadeOut 150

    $('.contributeC .response').fadeOut 250, ->
      resetContribute($('.contributeC'))

    $('.contributeC .main_content .shared').fadeOut 400, ->
      $(@).remove()
      resetContribute($self.parents('.contributeC:first'))

    $self.find('.cancel').fadeOut 150, ->
      $self.removeClass 'on', 150, ->
        $self.siblings('.option').fadeIn(100)

  setContributeToPicture = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_picture').attr('action'))
    talkForm.find('#talk_content').parents('.lClear:first').find('label').text('Talk about this picture...')

  setContributeToVideo = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_video').attr('action'))
    talkForm.find('#talk_content').parents('.lClear:first').find('label').text('Talk about this video...')

  setContributeToLink = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_link').attr('action'))
    talkForm.find('#talk_content').parents('.lClear:first').find('label').text('Talk about this link...')

  # fetch data from a link and update the contribute form
  $('.contributeC #link_fetch').live 'change', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        parentForm = self.parents('.contributeC:first')

        if data.limelight_post
          response = parentForm.find('.response')
          if data.limelight_post.image
            response.addClass('with-image').find('.image').html('<img src="'+data.limelight_post.image+'" />')
          response.find('.title').text(data.limelight_post.title)
          response.find('.created_at').text(data.limelight_post.type+' originally submitted to Limelight '+data.limelight_post.created_at+' ago')
          parentForm.find('#talk_parent_id').val(data.limelight_post.id)
          parentForm.find('#talk_content').parents('.lClear:first').find('label').text('Talk about this '+data.limelight_post.type+'...')
          response.fadeIn(250)
        else
          if data.embedly.oembed.type == 'video'
            clone = parentForm.find('.new_video').find('.shared').clone()
            clone.addClass('with-preview')
            provider = data.embedly.provider_name
            video_id = data.video_id
            html = data.video_html
            target = clone.find('.preview')

            if html
              target.html(html)
              clone.find('#video_embed_html').val(html)
            else
              target.html('<div class="none">Sorry, no video embed available.')

            clone.find('#video_source_url').val(data.embedly.url)

            clone.find('#video_source_name').val(provider)
            clone.find('#video_source_video_id').val(video_id)
            if data.embedly.images.length > 0
              clone.find('.remote_image_url').val(data.embedly.images[0].url)
            setContributeToVideo(parentForm)

          else if data.embedly.oembed.type == 'photo'
            clone = parentForm.find('.new_picture').find('.shared').clone()
            clone.removeClass('with-preview')
            clone.find('#picture_source_url').val(data.embedly.url)
            clone.find('#picture_source_name').val(data.embedly.provider_name)
            setContributeToPicture(parentForm)
          else
            clone = parentForm.find('.new_link').find('.shared').clone()
            clone.removeClass('with-preview')
            clone.find('#link_source_url').val(data.embedly.url)
            clone.find('#link_source_name').val(data.embedly.provider_name)
            setContributeToLink(parentForm)

          clone.find('.mention,.data').val(data.embedly.title)
          parentForm.find('.main_content').prepend(clone)
          clone.fadeIn 150

          if data.embedly.oembed.type != 'video' && data.embedly.images.length > 0
            clone.addClass('with-preview')
            target = clone.find('.preview .images')
            target.html('')

            for image in data.embedly.images
              target.append("<img src='"+image.url+"' />")

            target.find('img:not(:first)').hide()

            clone.find('.remote_image_url').val(target.find('img:first').attr('src'))

            if data.embedly.images.length > 1
              clone.find('.switcher').removeClass('hide')

          if data.embedly.title.length > 0
            suggestMentions(clone.find('.mention'))

        self.val('').blur().parent().fadeOut 150

      'json'
    )

  # update after the user uploads their own image
  $('.contribute_picture_image_data').live 'click', ->
    params = $(@).data('params')
    parentForm = $(@).parents('.contributeC:first')
    pictureForm = parentForm.find('.new_picture')
    clone = pictureForm.find('.shared').clone()
    parentForm.find('.main_content').prepend(clone)
    target = clone.find('.preview .images')

    clone.find('.image_upload_cache').val(params.image_location)
    target.html('<img src="'+params.image_location+'" />')

    parentForm.find('.picture_options').fadeOut 150
    clone.fadeIn 150

    $('#picture_fetch').val('').blur().parent().fadeOut(150)
    setContributeToPicture(parentForm)

  $('.contributeC .switcher .left').live 'click', (e) ->
    target = $(@).parents('.shared:first').find('.preview img:visible').hide()
    if target.prev().is('img')
      found = target.prev()
    else
      found = $(@).parents('.shared:first').find('.preview img:last')

    $(@).parents('.shared:first').find('.remote_image_url').val(found.attr('src'))
    found.show()

  $('.contributeC .switcher .right').live 'click', (e) ->
    target = $(@).parents('.shared:first').find('.preview img:visible').hide()
    if target.next().is('img')
      found = target.next()
    else
      found = $(@).parents('.shared:first').find('.preview img:first')

    $(@).parents('.shared:first').find('.remote_image_url').val(found.attr('src'))
    found.show()

  $('.contributeC .shared .cancel').live 'click', (e) ->
    $(@).parents('.contributeC:first').find('.option:visible .cancel').click()

  $('.contributeC .actions .cancel').live 'click', (e) ->
    $(@).parents('.contributeC:first').fadeOut(250)

  $('.contributeC .connect_twitter').live 'click', (e) ->
    $self = $(@)
    $.colorbox({
      title:false,
      transition: "elastic",
      speed: 100,
      opacity: '.95',
      fixed: true,
      html: '
        <h3 style="margin: 10px; width: 250px">
          You need to visit Twitter to authenticate.
          After authenticating you will need to re-enter your post.
          You only need to connect to twitter once!
        </h3>
        <div style="margin: 0 0 10px 10px;">
          <a href="'+$self.data('auth')+'">Continue Authenticating</a>
        </div>
      '
    })

  $('.contributeC .tweet input').live 'click', (e) ->
    target = $(@).parents('form:first').find('.tweet_content')
    target.toggle()

  # Title character counter
  $('.contributeC .title .mention').livequery (e) ->
    $(@).charCount({
      allowed: 125,
      warning: 20
    })

  # Content character counter
  $('.contributeC .talk_content .mention').livequery (e) ->
    $(@).charCount({
      allowed: 280,
      warning: 30
    })

  # Populate mention suggestions
  $('.mention-box .mention').live 'keyup', (e) ->
    suggestMentions($(@))

  $('form .suggestions .placeholder').live({
    mouseenter: ->
      $(@).find('.suggestion-group').show()
    mouseleave: ->
      $(@).find('.suggestion-group').hide()
  })

  # Handle mention suggestion selection
  $('form .suggestion').live 'click', (e) ->
    $self = $(@)
    $self.parents('form:first').find('.mention').trigger('addMention', [$(@).data('id'), $(@).data('text')])
    $self.parents('.placeholder:first').fadeOut 150, ->
      if $self.parents('.suggestions:first').find('.placeholder:visible').length == 0
        $self.parents('.suggestions:first').find('.none').show()

  ####
  # END CONTRIBUTE FORM
  ####

  ####
  # RESPONSE FORM
  ####

  $('.talk-response').live 'click', (e) ->
    $('.contributeC').hide()

    form = $('#contribute-'+$(@).data('id'))
    if form.length == 0
      form = $('#blank-contribute').clone()
      form.find('#talk_parent_id').val($(@).data('id'))
      form.addClass('responding').find('.options').remove()
      form.find('.responding').text('Talking about the '+$(@).data('type')+' "'+$(@).data('name')+'"')
      $('body').append(form)

    offset_x = $(@).offset().left - 10
    offset_y = $(@).offset().top + 20
    form_width = form.width()
    form_height = form.height()

    if (offset_x + form_width) > ($(window).width() - 20)
      offset_x -= (offset_x + form_width) - ($(window).width() - 20)

    if (offset_y + form_height) > ($(window).height() - 20)
      offset_y -= (offset_y + form_height) - ($(window).height() - 20)

    form.attr('id', 'contribute-'+$(@).data('id')).css({'position':'absolute','left':offset_x,'top':offset_y})
    form.fadeIn 250, ->
      $(@).find('#talk_content').click().focus()

  ####
  # END RESPONSE FORM
  ####

  ####
  # COMMENT FORM
  ####

  $('.comment-response').live 'click', (e) ->
    $('.comment_form').hide()

    form = $('#comment-form-'+$(@).data('id')+'-'+$(@).data('pid'))
    if form.length == 0
      form = $('#blank-comment').clone()
      form.find('#comment_talk_id').val($(@).data('id'))
      form.find('#comment_parent_id').val($(@).data('pid'))
      form.find('h4').text('Responding to '+$(@).data('t'))
      form.attr('id', 'comment-form-'+$(@).data('id')+'-'+$(@).data('pid'))
      $('body').append(form)

    offset_x = $(@).offset().left - 10
    offset_y = $(@).offset().top + 20
    form_width = form.width()
    form_height = form.height()

    if (offset_x + form_width) > ($(window).width() - 20)
      offset_x -= (offset_x + form_width) - ($(window).width() - 20)

    if (offset_y + form_height) > ($(window).height() - 20)
      offset_y -= (offset_y + form_height) - ($(window).height() - 20)

    form.css({'position':'absolute','left':offset_x,'top':offset_y})
    form.fadeIn 250, ->
      $(@).find('#comment_content').click().focus()

  $('.comment-cancel').live 'click', (e) ->
    $(@).parents('.comment_form:first').fadeOut(250)

  ####
  # END COMMENT FORM
  ####

  # mention boxes
  $('.mention').livequery ->
    $(@).mentionable()

  # show action buttons on teasers on hover
  $('.teaser .response,.teaser.talk').live({
    mouseenter: ->
      $(@).find('.comment-response,.likeB,.unlikeB,.coreShareB').show()
    mouseleave: ->
      $(@).find('.comment-response,.likeB,.unlikeB,.coreShareB').hide()
  })

  # Feed Sort Selection
  $('.feed-sort-select.closed').live 'click', (e) ->
    $(@).prepend($(@).find('.on').parent())
    $(@).children().removeClass('hide')
    $(@).removeClass('closed')

  $('.feed-sort-select:not(.closed)').live 'click', (e) ->
    $(@).find('.opt:not(.on)').parent().addClass('hide')
    $(@).addClass('closed')
    options = []
    $('.feed-sort-select .item').each (i,val) ->
      options[$(val).data('sort')] = val
    $(options).each (i,val) ->
      $('.feed-sort-select').append(val)

  # Automatically click the "load more" button if it is visible for more than .5 secs
  $(window).scroll ->
    if !$('#load-more').hasClass('on') && isScrolledIntoView($('#load-more'), true)
      $('#load-more').addClass('on')
      $('#load-more').oneTime(500, 'load_feed_page', ->
        $(@).click()
      )
    else if !isScrolledIntoView($('#load-more'), true)
      $('#load-more').removeClass('on')
      $('#load-more').stopTime('load_feed_page')

  $('#load-more').live 'click', (e) ->
    $(@).addClass('on')
    $(@).html("loading...")

  # Automatically click if visible on page load
  if $('#load-more').length > 0 && isScrolledIntoView($('#load-more'), true)
    $('#load-more').click()

  if ($('.teaser.column').length > 0)
    rearrange_feed_columns()

  # re-calculate column view on window resize
  $(window).resize ->
    $(window).stopTime('resize-column-feed')
    $(window).oneTime 500, "resize-column-feed", ->
      rearrange_feed_columns()